classdef Controller < handle
    properties(Constant)
        OP               = 10;                            % percent
        GC_THRESHOLD     = 2;                             % 2 blocks
    end
    
    properties
        amount_op_blocks;            % total OP blocks.
        amount_user_blocks;          % total blocks users can use.
        current_avl_usr_blocks_num;  % current ready blocks
        open_block_idx;              % the block id where is ready to be written
%         open_page_idx;               % the first available page id in the open block
        open_page_in_block_idx;      % the page id in the open block
        available_blocks_link;       % the queue of empty blocks
        closed_blocks_link;          % the queue of full blocks
        valid_pages_num_in_blk;      % how many valide pages in a block to be cycled
        l2p_tbl(1, :) = Tuple(0, 0); % logical addr to physic addr. Idx is the logic addr. (page offset, block_idx)
        p2l_tbl;                     % physic addr to logical addr. Idx is the physic addr.
%         valid_page_tbl;              % record the number of valid pages in a block
        nand;                        % a handler of a Nand object
        stm;                         % state machine handler
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = Controller()
            obj.amount_op_blocks = ceil(Nand.NAND_SIZE * (Controller.OP / 100));
            obj.amount_user_blocks = Nand.NAND_SIZE - obj.amount_op_blocks;
            obj.current_avl_usr_blocks_num = obj.amount_user_blocks;
            obj.available_blocks_link = Queue(Nand.NAND_SIZE); % at begining, all the blocks are available
            % init the link
            for i = 1 : Nand.NAND_SIZE
                obj.available_blocks_link.push(Tuple(0, i)); % (invalid_page_num, block_idx), but invalid_page is unused in this q.
            end
            
            obj.closed_blocks_link = Queue(Nand.NAND_SIZE); % just leave it empty
            % init the l2p table
            for n = 1 : obj.amount_user_blocks % one dimension from users' view
                obj.l2p_tbl(n) = Tuple(0, 0);
            end
            obj.p2l_tbl = zeros(Block.BLOCK_SIZE, Nand.NAND_SIZE); % 2 dimension from hardware's view
            
            obj.open_block_idx = 0;
            obj.nand = Nand();
            obj.stm = State_machine();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % used for modifying a user's page
        function obj = write_page(obj, usr_pg_idx)
            addr_tuple = obj.l2p_tbl(usr_pg_idx);
            if ~(addr_tuple.is_empty) % modify page
                % set the page as dirty page
                [pg_offset, blk_idx] = addr_tuple.get_tuple();
                obj.nand.blocks_array(1, blk_idx).set_page_dirty(pg_offset);
            end
            open_blk = obj.nand.blocks_array(obj.open_block_idx);
            % write the current available page
            open_blk.write_page();
            % update l2p table 
            current_avl_pg = open_blk.current_pg_idx;
            addr_tuple.set_tuple(current_avl_pg, obj.open_block_idx);
            % update p2l table
            obj.p2l_tbl(current_avl_pg, obj.open_block_idx) = usr_pg_idx;
            % update the page pointer
            open_blk.update_page_point();
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % used for GC, copying valide pages in source block to open block
        function obj = block_copy(obj, src_blk_idx)
            for i = 1 : Block.BLOCK_SIZE
                if obj.nand.blocks_array(src_blk_idx).pages_array(i) == Block.VALID_PAGE;
                    usr_pg_idx = obj.p2l_tbl(src_blk_idx, i);
                    obj.write_page(obj, usr_pg_idx);
                    obj.valid_pages_num_in_blk = obj.valid_pages_num_in_blk + 1;
                end
            end
            obj.available_blocks_link.push(Tuple(0, src_blk_idx));
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
                        disp(State_machine.START)
                        
                        if (obj.open_block_idx ~= 0) && (obj.nand.blocks_array(obj.open_block_idx).block_is_full()) % open block is full
                            % close the block
                            inv_page_num = obj.nand.blocks_array(obj.open_block_idx).get_num_of_invalide_pages();
                            
                            obj.closed_blocks_link.push(Tuple(inv_page_num, obj.open_block_idx));
                            obj.open_block_idx = 0;
                        end
                        if obj.open_block_idx == 0 % no open block yet
                            % here I don't implement the exception handler for no-space
                            % case.
                            % open a new block
                            tuple = obj.available_blocks_link.pop(Queue.CQ);
                            [~, obj.open_block_idx] = tuple.get_tuple();
                            %obj.open_page_idx = 1; % Matlab array starts with 1
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
                        current_val_blks = obj.available_blocks_link.get_current_q_len();
                        
                        if current_val_blks == Controller.GC_THRESHOLD
                            disp(State_machine.GARBAGE_COLLECTION)
                            gc_blk = obj.closed_blocks_link.pop(Queue.PQ);
                            disp("The GC block is:");
                            disp(gc_blk.blk_idx);
                            obj.block_copy(gc_blk.blk_idx);
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