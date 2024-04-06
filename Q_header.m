classdef Q_header < handle
    properties (Constant)
        IDX_END   = -1;
        PQ        = "priority queue"
        CQ        = "Common queue"
    end
    properties
        q_len; % how many nodes now
        q_max_len; % the max number of nodes in the link
        prev;
        next;
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = Q_header()
            obj.q_len = 0;
            obj.prev = Q_header.IDX_END;
            obj.next = Q_header.IDX_END;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = push(obj, blk, array)
            assert(obj.q_len <= Nand.NAND_SIZE, "queue is full already!!");
            if(obj.q_len == 0)
                obj.next = blk.blk_idx;
                obj.prev = blk.blk_idx;
                blk.q.next = Q_header.IDX_END;
                blk.q.prev = Q_header.IDX_END;
            else
                last_node = array(obj.prev);
                obj.prev = blk.blk_idx;
                last_node.q.next = blk.blk_idx;
                blk.q.prev = last_node.blk_idx;
                blk.q.next = Q_header.IDX_END;
            end
            obj.q_len = obj.q_len + 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        % this is a priority Q, the node poped always has the highest
        % number of invalid pages 
        function blk = pop(obj, array, mode) 
            assert(obj.q_len ~= 0, "queue is empty!!")
            % find the node which has the highest number of invalid pages
            if mode == Q_header.PQ
                start_idx = obj.next;
                max_inv = 0;
                max_inv_idx = 0;
                while(start_idx ~= Q_header.IDX_END)
                    blk = array(start_idx);
                    if blk.num_of_inv_pages > max_inv
                        max_inv_idx = start_idx;
                        max_inv = blk.num_of_inv_pages;
                    end
                    start_idx = blk.q.next;
                end
                % remove the node just found
                blk = array(max_inv_idx);
                
                if (blk.q.prev ~= Q_header.IDX_END) && (blk.q.next ~= Q_header.IDX_END)
                    prev_blk = array(blk.q.prev); 
                    next_blk = array(blk.q.next);
                    prev_blk.q.next = next_blk.blk_idx;
                    next_blk.q.prev = prev_blk.blk_idx;
                elseif (blk.q.prev == Q_header.IDX_END) && (blk.q.next ~= Q_header.IDX_END)
                    next_blk = array(blk.q.next);
                    obj.next = next_blk.blk_idx;
                    next_blk.q.prev = Q_header.IDX_END;
                elseif (blk.q.prev ~= Q_header.IDX_END) && (blk.q.next == Q_header.IDX_END)
                    prev_blk = array(blk.q.prev); 
                    prev_blk.q.next = Q_header.IDX_END;
                    obj.prev = prev_blk.blk_idx;
                else
                    assert(obj.q_len ~= 0, "queue is empty!!")
                end
                
            else
                blk = array(obj.next);
                next_blk = array(blk.q.next);
                next_blk.q.prev = Q_header.IDX_END;
                obj.next = next_blk.blk_idx;
                blk.q.next = 0;
                blk.q.prev = 0;
            end
            
            obj.q_len = obj.q_len - 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function q_len = get_current_q_len(obj)
            q_len = obj.q_len;
        end
    end
end