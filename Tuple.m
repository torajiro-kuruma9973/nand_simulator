classdef Tuple < handle
    properties
        first;
        second;
    end
    
    methods
        function obj = Tuple(first, second)
            obj.first = first;
            obj.second = second;
        end
        
        function rst = is_empty(obj)
            rst = obj.first == 0 && obj.second == 0;
        end
        
        function obj = set_tuple(obj, first, second)
            obj.first = first;
            obj.second = second;
        end
        
        function [first, second] = get_tuple(obj)
            first = obj.first;
            second = obj.second;
        end
    end
end