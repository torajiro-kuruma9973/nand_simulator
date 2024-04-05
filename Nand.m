classdef Nand < handle
    properties(Constant)
        NAND_SIZE = 8;                          % 1024 blocks per NAND
    end
    
    properties
        nand_space_array(1, :) = Block();       % hard code here due to the matlab        
    end
    
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    methods
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
       function obj = Nand()
           for n = 1 : Nand.NAND_SIZE
               obj.nand_space_array(1, n) = Block();
           end
       end
       
    end
    
end
