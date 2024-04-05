classdef Queue < handle
    properties (Constant)
        IDX_END = -1;
        CQ      = "CQ";                          % common q
        PQ      = "PQ";                          % priority q
    end
    properties
        head;
        tail;
        q(1, :) = Block;
        max_len; % max buffer length
        q_len; % how many elements now
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = Queue(q_max_len)
            obj.head = 0;
            obj.tail = 0;
            for n = 1 : q_max_len
                obj.q(n) = Block();
            end
            
            obj.max_len = q_max_len;
            obj.q_len = 0;
        end
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function obj = push(obj, content)
            assert(obj.q_len ~= obj.max_len, "queue is full already!!");
            if obj.head == 0 % empty queue
                obj.head = 1;
                obj.q(obj.head) = content;
                obj.tail = 2;
                obj.q_len = obj.q_len + 1;
            else
                obj.q(obj.tail) = content;
   
                if(obj.tail + 1 > obj.max_len)
                    obj.tail = 1;
                else
                    obj.tail = obj.tail + 1;
                end
                obj.q_len = obj.q_len + 1;
            end
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        function content = pop(obj, mode)
            assert(obj.q_len ~= 0, "queue is empty!!")
            if(mode == "PQ")
                %[~, idx_v] = sort(obj.q, 2, 'descend'); % priority Q, always pops max value
                %obj.q = obj.q(:, idx_v(1, :));
                [~, vec] = sort([obj.q.num_of_inv_pages], 'descend');
                obj.q = obj.q(vec);
            end
            content = obj.q(obj.head);
          
            if(obj.head + 1 > obj.max_len)
                obj.head = 1;
            else
                obj.head = obj.head + 1;
            end
            obj.q_len = obj.q_len - 1;
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        function q_len = get_current_q_len(obj)
            q_len = obj.q_len;
        end
    end
end