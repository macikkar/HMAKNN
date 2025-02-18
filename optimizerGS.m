classdef optimizerGS < baseOptimizer

   
    methods
        
        function gs = optimizerGS(params)
            gs@baseOptimizer(params, 'Grid Search', 'GS');

            gridSizes=num2cell(gs.getHPGridSizes());
            strgridSizes=strtrim(sprintf("%d ", gridSizes{:} ));
            
            gs.description=sprintf('%s-GridSize[%s]', gs.shortName, strgridSizes);
        end

   
        function [optparams, execTime, createdModel, optInfo, minError ] = optFunction(gs, costFunction)

            
            
%             if gs.noParamCount>0
%                 [novalues, noindices, nonames]=gs.getHPForGS(false);
%                 
%                 nohyperParamValues=array2table(combvec(novalues{:})', "VariableNames", nonames);
%                 nohyperParamIndices=array2table(combvec(noindices{:})', "VariableNames", strcat('i',nonames));
% 
%                 %hyperParamValues=[hyperParamValues nohyperParamValues];
%             end
% 
%             if gs.oParamCount>0
%                 [ovalues, oindices, onames]=gs.getHPForGS(true);
%                 
%                 ohyperParamValues=array2table(combvec(ovalues{:})', "VariableNames", onames);
%                 ohyperParamIndices=array2table(combvec(oindices{:})', "VariableNames", strcat('i',onames));
% 
%                 %hyperParamValues=[hyperParamValues nohyperParamValues];
%             end
% 
% 
%             for i=0:gs.noParamCount
% 
%                 if gs.noParamCount==0
%                     continue
%                 end
% 
% 
%             end

            variableNames=gs.getHPNames();
            [values, indices]=gs.getHPForGS();
            
            hyperParamValues=array2table(combvec(values{:})', "VariableNames", variableNames);
            hyperParamIndices=array2table(combvec(indices{:})', "VariableNames", strcat('i',variableNames));



            paramSetRowCount =size(hyperParamValues, 1);
            errorValues=zeros(paramSetRowCount,1);

            startTime=tic;

            minError=Inf;
            for i=1:1:paramSetRowCount

                params=hyperParamValues(i, :);

                currentError = costFunction(params);
                
                errorValues(i)=currentError;
           
                if(currentError<minError)
                    minError=currentError;

                    optparams=params;
                end             

            end
            
            execTime=toc(startTime);

            createdModel=paramSetRowCount;

            
                        
            optInfo=array2table([errorValues gs.getErrorValuesSoFar(errorValues) ], 'VariableNames', {'ERR', 'ERRSoFar'});

            optInfo=[hyperParamValues optInfo hyperParamIndices];

        end  
        
    end
end

