classdef Nand < handle
    properties(Constant)
        NAND_SIZE = 8;                          % 1024 blocks per NAND
    end
    
    properties
        blocks_array(1, :) = Block();       % hard code here due to the matlab        
    end
    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       function obj = Nand()
           for n = 1 : Nand.NAND_SIZE
               obj.blocks_array(1, n) = Block();
               obj.blocks_array(1, n).set_block_idx(n);
           end
       end
       
    end
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end
