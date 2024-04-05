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
        %open_page_idx;               % the first available page id in the open block
        open_page_in_block_idx;      % the page id in the open block
        available_blocks_link;       % the queue of empty blocks
        closed_blocks_link;          % the queue of full blocks
        l2p_tbl(1, :) = Tuple(0, 0); % logical addr to physic addr. Idx is the logic addr. (page offset, block_idx)
        p2l_tbl;                     % physic addr to logical addr. Idx is the physic addr.
        %valid_page_tbl;              % record the number of valid pages in a block
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
                obj.available_blocks_link.push(Tuple(0, i)); % (invalid_page_num, block_idx)
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
        function obj = user_write_page(obj, user_pg_idx) 
            assert(obj.stm.get_state() == State_machine.END, "The state machine is not clean!!");
            obj.stm.set_state(State_machine.START);
            while (1)
                stt = obj.stm.get_state();
                switch(stt)
                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.START
                        disp(State_machine.START)
                        
                        if (obj.open_block_idx ~= 0) && (obj.nand.nand_space_array(obj.open_block_idx).block_is_full()) % open block is full
                            % close the block
                            inv_page_num = obj.nand.nand_space_array(obj.open_block_idx).get_num_of_invalide_pages();
                            
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
                        obj.stm.set_state(State_machine.WRITE_PAGE);

                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.WRITE_PAGE
                        disp(State_machine.WRITE_PAGE)
%                         blk_idx = ceil(user_pg_idx / Block.BLOCK_SIZE);
%                         pg_offset = user_pg_idx - blk_idx * Block.BLOCK_SIZE;
                        addr_tuple = obj.l2p_tbl(user_pg_idx);
                        
                        if ~(addr_tuple.is_empty) % modify page
                            % set the page as dirty page
                            [pg_offset, blk_idx] = addr_tuple.get_tuple();
                            obj.nand.nand_space_array(1, blk_idx).set_page_dirty(pg_offset);
                        end
                        % write the current available page
                        obj.nand.nand_space_array(obj.open_block_idx).write_page();
                        % update l2p table 
                        current_avl_pg = obj.nand.nand_space_array(obj.open_block_idx).current_pg_idx;
                        addr_tuple.set_tuple(current_avl_pg, obj.open_block_idx);
                        % update p2l table
                        obj.p2l_tbl(current_avl_pg, obj.open_block_idx) = user_pg_idx;
                        % update the page pointer
                        obj.nand.nand_space_array(obj.open_block_idx).update_page_point();
                        
                        obj.stm.set_state(State_machine.GARBAGE_COLLECTION);
                    %%%%%%%%%%%%%%%%%%%%%%
                    case State_machine.GARBAGE_COLLECTION
                        current_val_blks = obj.available_blocks_link.get_current_q_len();
                        
                        if current_val_blks < Controller.GC_THRESHOLD
                        else
                            obj.stm.set_state(State_machine.END);
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