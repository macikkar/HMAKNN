classdef baseOptimizer < handle

    properties
        name=''
        shortName=''
        description=''

        params
        paramCount=0;
        options=struct;

        order=0

        empty=false;
    end

    methods

        function base = baseOptimizer(params, name, shortName)
            base.params=params;
            base.paramCount=numel(params);

            base.name=name;
            base.shortName=shortName;
            base.empty=false;
        end

        function names=getHPNames(hps)
            if hps.empty
                names={}; return
            end

            names=cell(1, hps.paramCount);

            for i=1:hps.paramCount
                names{1, i}=hps.params(i).name;
            end
        end


        function [values, indices]=getHPForGS(hps)
            if hps.empty
                values={}; indices={}; return
            end

            values=cell(1, hps.paramCount);
            indices=cell(1, hps.paramCount);

            for i=1:hps.paramCount
                param=hps.params(i);
                values{i}=param.values;
                indices{i}=param.indices;
            end
        end


        function gridSizes=getHPGridSizes(hps)
            if hps.empty
                gridSizes=[]; return
            end

            gridSizes=zeros(1, hps.paramCount);

            for i=1:hps.paramCount
                gridSizes(1, i)=hps.params(i).gridSize;
            end
        end

        function ovars=getHPForBO(hps)
            ovars= optimizableVariable.empty(0);
            if hps.empty
                return
            end

            for i=1:hps.paramCount
                param=hps.params(i);
                ovars(1, i)=param.getForBO();
            end
        end

        function [nvars, lb, ub]=getHPForPSO(hps)

            if hps.empty
                nvars=0; lb=[]; ub=[]; return
            end

            nvars=hps.paramCount;
            lb=zeros(1, nvars);
            ub=zeros(1, nvars);

            for i=1:hps.paramCount
                r=hps.params(i).range;
                lb(1, i)=r(1);
                ub(1, i)=r(2);
            end
        end


        function values=getErrorValuesSoFar(hps, errorValues)
            if hps.empty
                values=[]; return
            end            
            len=length(errorValues);

            values=zeros(len, 1);
            minValue=Inf;

            for i=1:len
                if minValue>errorValues(i)
                    minValue=errorValues(i);
                end

                values(i)=minValue;
            end
        end

    end

end


%         function [values, indices, names]=getHPForGS(hps, optimizable)
%             xcount=0;
%             xparams=hyperParam.empty(0);
% 
%             if optimizable==true
%                 xcount=hps.oParamCount;
%                 xparams=hps.oParams;
%             else
%                 xcount=hps.noParamCount;
%                 xparams=hps.noParams;
%             end
% 
%             values=cell(1, xcount);
%             indices=cell(1, xcount);
%             names=cell(1, xcount);
% 
% 
%             if xcount>0
% 
%                 for i=1:xcount
%                     param=xparams(i);
%                     values{i}=param.values;
%                     indices{i}=param.indices;
%                     names{i}=param.name;
%                 end
% 
%             end
%         end



%             base.oParams=hyperParam.empty(0);
%             base.noParams=hyperParam.empty(0);
%             base.oParamCount=0;
%             base.noParamCount=0;
% 
%             for i=1:base.paramCount
%                 param=params(i);
% 
%                 if param.optimize==true
%                     base.oParamCount=base.oParamCount+1;
%                     base.oParams(1, base.oParamCount)=param;
%                 else
%                     base.noParamCount=base.noParamCount+1;
%                     base.noParams(1, base.noParamCount)=param;
%                 end
%             end



