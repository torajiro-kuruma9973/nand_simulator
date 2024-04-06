classdef Block < handle
    properties(Constant)
        BLOCK_SIZE = 16;   % 64 pages per block
        INVALID_PAGE = -1;
        EMPTY_PAGE = 0;
    end
    properties
        blk_idx;
        current_pg_idx;    % the available page offset in this block
        pages_array;    
        num_of_inv_pages;  % how many invalid pages in this block
        q;                 % node information
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = Block()
            obj.current_pg_idx = 1;
            obj.pages_array = zeros(1, Block.BLOCK_SIZE); % at begining, all the pages are empty
            obj.num_of_inv_pages = 0;
            obj.q = Queue();
        end
        
        function obj = set_block_idx(obj, n)
            obj.blk_idx = n;
        end
        
        function inv_num = get_num_of_invalide_pages(obj)
            inv_num = sum(obj.pages_array(1, :) == Block.INVALID_PAGE);
        end
        
        function obj = write_page(obj, data)
            assert(obj.current_pg_idx <= Block.BLOCK_SIZE)
            assert(data > 0)
            obj.pages_array(obj.current_pg_idx) = data;
            obj.current_pg_idx = obj.current_pg_idx + 1;
        end
        
        function rst = block_is_full(obj)
            rst = obj.current_pg_idx > Block.BLOCK_SIZE;
        end
        
%         function obj = update_page_point(obj)
%             obj.current_pg_idx = obj.current_pg_idx + 1;
%         end

        function obj = erase(obj)
            obj.current_pg_idx = 1;
            obj.num_of_inv_pages = 0;
            for n = 1 : Block.BLOCK_SIZE
                obj.pages_array(1, n) = Block.EMPTY_PAGE;
            end
        end
        
        function obj = set_page_dirty(obj, page_offset)
            obj.pages_array(page_offset) = Block.INVALID_PAGE;
            obj.num_of_inv_pages = obj.num_of_inv_pages + 1;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end