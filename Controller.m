classdef Controller < handle
    properties(Constant)
        OP               = 10;                            % percent
        GC_THRESHOLD     = 2;                             % 2 blocks
    end
    
    properties
        amount_op_blocks;            % total OP blocks.
        amount_user_blocks;          % total blocks users can use.
        amount_user_pages;           % total pages users can use.
%         current_avl_usr_blocks_num;  % current ready blocks
        open_block;                  % the block which is ready to be written
        virtual_blk;                 % matlab dosen't support null, so here I use a virtual blk whose idx is 0
%         open_page_idx;               % the first available page id in the open block
        open_page_in_block_idx;      % the page id in the open block
        valid_pages_num_in_blk;      % how many valide pages in a block to be cycled
        l2p_tbl;                     % logical addr to physic addr. row idx is the logic addr. col is (block_idx, page offset)
        p2l_tbl;                     % physic addr to logical addr. Idx is the physic addr.
%         valid_page_tbl;              % record the number of valid pages in a block
        nand;                        % a handler of a Nand object
        stm;                         % state machine handler
        avl_q_header;                % management of Q of available blocks
        closed_q_header;             % management of Q of closed blocks
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = Controller()
            obj.nand = Nand();
            obj.amount_op_blocks = ceil(Nand.NAND_SIZE * (Controller.OP / 100));
            obj.amount_user_blocks = Nand.NAND_SIZE - obj.amount_op_blocks;
            obj.amount_user_pages = obj.amount_user_blocks * Block.BLOCK_SIZE;
%             obj.current_avl_usr_blocks_num = obj.amount_user_blocks;
        
            % init the l2p table
            obj.l2p_tbl = zeros(obj.amount_user_pages, 2);
            for n = 1 : obj.amount_user_blocks % (n, 1): block idx. (n, 2): page offset.
                obj.l2p_tbl(n, 1) = 0;
                obj.l2p_tbl(n, 2) = 0;
            end
            
            obj.p2l_tbl = zeros(Nand.NAND_SIZE, Block.BLOCK_SIZE); % 2 dimension from hardware's view
            
            obj.virtual_blk = Block();
            obj.virtual_blk.set_block_idx(0);
            obj.open_block = obj.virtual_blk;

            obj.stm = State_machine();
            obj.avl_q_header = Q_header();
            for i = 1 : Nand.NAND_SIZE
                blk = obj.nand.blocks_array(i);
                obj.avl_q_header.push(blk, obj.nand.blocks_array);
            end
            obj.closed_q_header = Q_header();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % used for modifying a user's page
        function obj = write_page(obj, usr_pg_idx)
            blk_idx = obj.l2p_tbl(usr_pg_idx, 1);
            pg_offset = obj.l2p_tbl(usr_pg_idx, 2);
            if ~(pg_offset == 0 && blk_idx == 0) % modify page
                % set the page as dirty page
                obj.nand.blocks_array(blk_idx, 1).set_page_dirty(pg_offset);
            end
            open_blk = obj.nand.blocks_array(obj.open_block.blk_idx);
            % update l2p table
            obj.l2p_tbl(usr_pg_idx, 1) = open_blk.blk_idx;
            obj.l2p_tbl(usr_pg_idx, 2) = open_blk.current_pg_idx;
            % update p2l table
            obj.p2l_tbl(open_blk.blk_idx, open_blk.current_pg_idx) = usr_pg_idx;
            % write the current available page
            open_blk.write_page(usr_pg_idx);
   
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % used for GC, copying valide pages in source block to open block
        function obj = block_copy(obj, src_blk, array)
            for i = 1 : Block.BLOCK_SIZE
                if src_blk.pages_array(1, i) > 0 % valid page
                    usr_pg_idx = obj.p2l_tbl(src_blk.blk_idx, i);
                    obj.write_page(usr_pg_idx);
                    obj.valid_pages_num_in_blk = obj.valid_pages_num_in_blk + 1;
                end
            end
            disp("Amp: " + obj.valid_pages_num_in_blk);
            obj.valid_pages_num_in_blk = 0; % clear for next session
            src_blk.erase();
            obj.avl_q_header.push(src_blk, array);
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = user_write_page(obj, user_pg_idx) 
            assert(obj.stm.get_state() == State_machine.END, "The state machine is not clean!!");
            obj.stm.set_state(State_machine.START);
            while (1)
                stt = obj.stm.get_state();
                switch(stt)
                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.START
                        %disp(State_machine.START)
                        open_block_idx = obj.open_block.blk_idx;
                        if (open_block_idx ~= 0) && (obj.nand.blocks_array(open_block_idx).block_is_full()) % open block is full
                            % close the block
                            %inv_page_num = obj.nand.blocks_array(open_block_idx).get_num_of_invalide_pages();
                            obj.closed_q_header.push(obj.open_block, obj.nand.blocks_array);
                            obj.open_block = obj.virtual_blk;
                        end
                        if obj.open_block == obj.virtual_blk % no open block yet
                            % here I don't implement the exception handler for no-space
                            % case.
                            % open a new block
                            obj.open_block = obj.avl_q_header.pop(obj.nand.blocks_array, Q_header.CQ);
                        end
                        % to check if garbage collection is needed
                        obj.stm.set_state(State_machine.GARBAGE_COLLECTION);
                   
                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.WRITE_PAGE
                        disp(State_machine.WRITE_PAGE)
                        obj.write_page(user_pg_idx);
                        obj.stm.set_state(State_machine.END);
                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.GARBAGE_COLLECTION
                        current_val_blks = obj.avl_q_header.get_current_q_len();
                        
                        if current_val_blks == Controller.GC_THRESHOLD
                            disp(State_machine.GARBAGE_COLLECTION)
                            gc_blk = obj.closed_q_header.pop(obj.nand.blocks_array, Q_header.PQ);
                            disp("The GC block is:");
                            disp(gc_blk.blk_idx);
                            obj.block_copy(gc_blk, obj.nand.blocks_array);
                        else
                            obj.stm.set_state(State_machine.WRITE_PAGE);
                        end
                        
                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.END
                        break; % jump out the while loop
                end 
            end
                
        end
    end      
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end