classdef optimizerBO < baseOptimizer
    
    methods
        
        function bo = optimizerBO(params, maxEvaluations, useParallel)
            bo@baseOptimizer(params, 'Bayesian Optimization', 'BO');
            
            bo.description=sprintf('%s-MaxEval[%d]', bo.shortName, maxEvaluations);
                        
            bo.options.MaxObjectiveEvaluations=maxEvaluations;
            bo.options.UseParallel=useParallel;
            bo.options.ShowInfo=false;
         
        end
        
  
        
        function [optimals, execTime, createdModel, optInfo, minError ] = optFunction(bo, costFunction)
            verbose=0;
            if bo.options.ShowInfo
                verbose=1;
            end

            ovars=bo.getHPForBO();


            startTime=tic;

            boBase = bayesopt(costFunction, ovars, 'UseParallel', bo.options.UseParallel, ...
                'Verbose', verbose, 'MaxObjectiveEvaluations', bo.options.MaxObjectiveEvaluations, 'PlotFcn', []);
            
            execTime=toc(startTime);

            optimals=boBase.XAtMinObjective;

            
            createdModel=boBase.NumObjectiveEvaluations;

            hyperParamValues=boBase.XTrace;
            accValues=boBase.ObjectiveTrace;
                        
            optInfo=array2table([accValues bo.getErrorValuesSoFar(accValues)], 'VariableNames', {'ERR' 'ERRSoFar'});
            optInfo=[hyperParamValues optInfo];
            
            minError=min(optInfo.ERR);

        end  
        

        
    end
end

