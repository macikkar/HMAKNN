classdef optimizerEmpty < baseOptimizer

   
    methods
        
        function eo = optimizerEmpty(params)
            eo@baseOptimizer(params, 'Empty Optimizer', 'EO');

            eo.description='';
            eo.empty=true;
        end

   
        function [optparams, execTime, createdModel, optInfo, minError ] = optFunction(~, ~)
            
            optparams=table();
            execTime=0;
            createdModel=0;
            optInfo=table();
            minError=0;

        end  
        
    end
end

