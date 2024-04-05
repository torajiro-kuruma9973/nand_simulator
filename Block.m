classdef Block < handle
    properties(Constant)
        BLOCK_SIZE = 4;   % 64 pages per block
        VALID_PAGE = 1;
        INVALID_PAGE = -1;
        EMPTY_PAGE = 0;
    end
    properties
        blk_idx;
        current_pg_idx;  % the available page offset in this block
        pages_array;     
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
        function obj = Block()
            obj.current_pg_idx = 1;
            obj.pages_array = zeros(1, Block.BLOCK_SIZE); % at begining, all the pages are empty
        end
        
        function obj = set_block_idx(obj, n)
            obj.blk_idx = n;
        end
        
        function inv_num = get_num_of_invalide_pages(obj)
            inv_num = sum(obj.pages_array(1, :) == Block.INVALID_PAGE);
        end
        
        function obj = write_page(obj)
            assert(obj.current_pg_idx <= Block.BLOCK_SIZE)
            obj.pages_array(obj.current_pg_idx) = Block.VALID_PAGE;
        end
        
        function rst = block_is_full(obj)
            rst = obj.current_pg_idx > Block.BLOCK_SIZE;
        end
        
        function obj = update_page_point(obj)
            obj.current_pg_idx = obj.current_pg_idx + 1;
        end
        function obj = erase(obj)
            obj.current_pg_idx = 1;
            for n = 1 : Block.BLOCK_SIZE
                obj.pages_array(1, n) = Block.EMPTY_PAGE;
            end
        end
        
        function obj = set_page_dirty(obj, page_offset)
            obj.pages_array(page_offset) = Block.INVALID_PAGE;
        end
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end