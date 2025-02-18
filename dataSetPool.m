classdef dataSetPool<handle

    
    properties
        dataSets={};
        dataSetCount=0;
        kFold=10
        subkFold=5
        runs=30
        name
    end
    
    methods
        function pool = dataSetPool(name, runs, kFold, subkFold)
            pool.dataSetCount = 0;
            
            pool.name=name;
            pool.runs=runs;
            pool.kFold=kFold;
            pool.subkFold=subkFold;
            
        end

        function  addR(pool, dataSetName)
            ds=dataSetDef(pool.name, dataSetName, false, pool.runs, pool.kFold, pool.subkFold);
            
            pool.dataSetCount = pool.dataSetCount+1;
            pool.dataSets{pool.dataSetCount}=ds;
            
        end
        
        function  addC(pool, dataSetName)
            ds=dataSetDef(pool.name, dataSetName, true, pool.runs, pool.kFold, pool.subkFold);
            
            pool.dataSetCount = pool.dataSetCount+1;
            pool.dataSets{pool.dataSetCount}=ds;
            
        end
        
        function  addApplyRelieff(pool, dataSetName)
            
            
            
            ds=dataSetDef(pool.name, dataSetName, true, pool.runs, pool.kFold, pool.subkFold);
            
            
            dataset=ds.dataSet.data;
            
            variables=dataset.Properties.VariableNames;
            X=table2array(dataset(:,1:end-1));
            Y=table2array(dataset(:,end));
            
            [r, ~]=relieff(X, Y, 9, 'method', 'classification');
            
           
            for i=length(r):-1:1
                cols=r(1:i);
                
                newX=X(:,cols);
                newVariables=variables(cols);
                newVariables{i+1}='Y';
                
                newData=array2table( [newX Y], 'VariableNames', newVariables);
                
                newDs=copy(ds);
                
                newDs.dataSet.name=sprintf('%s-%d',dataSetName, i);
                newDs.dataSet.data=newData;
                newDs.dataSet.targetName=newData.Properties.VariableNames{end};              
                
                pool.dataSetCount = pool.dataSetCount+1;
                pool.dataSets{pool.dataSetCount}=newDs;
                
            end
            
        end
        
        function  addApplyLASSO(pool, dataSetName)
            
            
            %ds=dataSetDef(dataSetName, true, pool.runs, pool.kFold, pool.subkFold);
            ds=dataSetDef(pool.name, dataSetName, true, pool.runs, pool.kFold, pool.subkFold);
            
            
            dataset=ds.dataSet.data;
            
            variables=dataset.Properties.VariableNames(1:end-1);
            X=table2array(dataset(:,1:end-1));
            Y=table2array(dataset(:,end));
            
            
            %variablesx={'CT', 'UCSize', 'UCShape', 'MA', 'SECS', 'BN', 'BC', 'NN', 'M'}
            
            [B,FitInfo] = lasso(X,Y, 'CV', pool.subkFold,'PredictorNames', variables);
            
            idxLambdaMinMSE = FitInfo.IndexMinMSE;
     
            ranks=B(:,idxLambdaMinMSE)';
            cols=ranks>0;

            
            newX=X(:,cols);
            newVariables=variables(cols);
            newVariables{end+1}='Y';
            
            newData=array2table( [newX Y], 'VariableNames', newVariables);
                
            newDs=copy(ds);

            newDs.dataSet.name=sprintf('%s-%s',dataSetName, 'L');
            newDs.dataSet.data=newData;
            newDs.dataSet.targetName=newData.Properties.VariableNames{end};              

            pool.dataSetCount = pool.dataSetCount+1;
            pool.dataSets{pool.dataSetCount}=newDs;
            

            
            
            
            
            
            %[r, ~]=relieff(X, Y, 9, 'method', 'classification');
            
           
%             for i=length(r):-1:1
%                 cols=r(1:i);
%                 
%                 newX=X(:,cols);
%                 newVariables=variables(cols);
%                 newVariables{i+1}='Y';
%                 
%                 newData=array2table( [newX Y], 'VariableNames', newVariables);
%                 
%                 newDs=copy(ds);
%                 
%                 newDs.dataSet.name=sprintf('%s-%d',dataSetName, i);
%                 newDs.dataSet.data=newData;
%                 newDs.dataSet.targetName=newData.Properties.VariableNames{end};              
%                 
%                 pool.dataSetCount = pool.dataSetCount+1;
%                 pool.dataSets{pool.dataSetCount}=newDs;
%                 
%             end
            
            

            
        end
        
        
        
        function ds=getDataSet(pool, index)
           ds=pool.dataSets{index};
        end
    end
end

