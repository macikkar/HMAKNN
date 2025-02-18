classdef optimizerPSO < baseOptimizer
    
    methods
        
        function pso = optimizerPSO(params, maxIterations, swarmSize, useParallel)
            
            pso@baseOptimizer(params, 'Particle Swarm Optimization', 'PSO');
            
            pso.description=sprintf('%s-MaxIter[%d]-Swarm[%d]', pso.shortName, maxIterations, swarmSize);
                        
            pso.options.SwarmSize=swarmSize;
            pso.options.MaxIterations=maxIterations;
            
            pso.options.InertiaRange=[0.1, 1.1];
            pso.options.UseParallel=useParallel;
            pso.options.ShowInfo=false;
                      
        end
               
        
        
        function [optimals, execTime, createdModel, optInfo, minError ] = optFunction(pso, costFunction)

            display='none';
            if pso.options.ShowInfo
                display='iter';
            end
            
            hyperParamValues=[];errorValues=[];

            [nvars, lb, ub]=pso.getHPForPSO();

            ooptions = optimoptions('particleswarm', ...
                'SwarmSize', pso.options.SwarmSize, 'MaxIterations', pso.options.MaxIterations, 'InertiaRange', pso.options.InertiaRange, ...
                'Display', display, 'UseParallel', pso.options.UseParallel, 'OutputFcn', @outfun);

            startTime=tic;

            [hps,~ ,~ ,output] = particleswarm(costFunction, nvars, lb, ub, ooptions);

            execTime=toc(startTime);

            optimals=array2table(hps, 'VariableNames', pso.getHPNames());

            createdModel=output.funccount;
            
            
            optInfo=array2table([errorValues pso.getErrorValuesSoFar(errorValues)], 'VariableNames', {'ERR' 'ERRSoFar'});

            variableNames=cellstr(pso.getHPNames());
            optInfo=[array2table(hyperParamValues, 'VariableNames', variableNames) optInfo];

            minError=min(optInfo.ERR);


            function [stop] = outfun(optimValues, state)

                startIndex=optimValues.iteration*pso.options.SwarmSize+1;
                endIndex=optimValues.funccount;

                hyperParamValues(startIndex:endIndex , :)=optimValues.swarm;
                errorValues(startIndex:endIndex, :)=optimValues.swarmfvals;

                state;
                stop=false;
            end


        end  
        

        
    end
end



