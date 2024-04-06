classdef Queue < handle
    properties
        next;
        prev;
    end
    
    methods
    
        function obj = Queue()
            obj.next = 0;
            obj.prev = 0;
        end
        
        
    end
end