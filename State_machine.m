classdef State_machine < handle
    properties(Constant)
        START = "Start...";
        GARBAGE_COLLECTION = "Garbage collection";
        CONVERT_ADDR = "Convert address";
        WRITE_PAGE = "Write page";
        END = "End...";
    end
    properties
        state;
    end
    
    methods
        function obj = State_machine(obj)
            obj.state = State_machine.END;
        end
        
        function set_state(obj, state)
            obj.state = state;
        end
        
        function st = get_state(obj)
            st = obj.state;
        end
    end
end