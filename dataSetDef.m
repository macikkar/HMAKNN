classdef dataSetDef<matlab.mixin.Copyable

    properties 
        fileName
        dataSet
        runs
        kFold
        subkFold
        indices
        foldsSubIndices

        rowCount
    end
    
    methods
        function ds = dataSetDef(poolName, dataSetName, isClassification, runs, kFold, subkFold)
            
            ds.fileName=sprintf('data/%s/data%s.mat', poolName, dataSetName);
            ds.dataSet.isClassification=isClassification;
            ds.runs=runs;
            ds.kFold=kFold;
            ds.subkFold=subkFold;
            
            load(ds.fileName, 'data');

            %data

            targetName=data.Properties.VariableNames{end};
            if isClassification
                [labels, ~, values] = unique(data.(targetName),'stable');
                data.(targetName)=values;

                ds.dataSet.classLabels=labels;
                ds.dataSet.classCount=numel(labels);
                ds.dataSet.classValues=unique(values,'stable');
            end

            ds.dataSet.targetName=targetName;%data.Properties.VariableNames{end};
            
            ds.dataSet.name=dataSetName;
            ds.dataSet.rowCount=size(data, 1);
            ds.dataSet.data=data;



            cvFileName=sprintf('data/%s/.cv-%s-ic%s-f%s-sf%s.mat', poolName, dataSetName, num2str(ds.runs), num2str(ds.kFold), num2str(ds.subkFold));

            if exist(cvFileName, 'file')==false
                ds.saveCVIndices(cvFileName);
            end

            load(cvFileName, 'cvIndices');

            ds.indices = cvIndices(:, 1);
            ds.foldsSubIndices = cvIndices(:, 2);
            
        end


        %%

        function saveCVIndices(ds, fileName)

            cvIndices=cell(ds.runs,2);

            for run=1:ds.runs

                xindices = crossvalind('Kfold', ds.dataSet.rowCount , ds.kFold);

                cvIndices{run, 1}=xindices;

                crossValSubIndices=cell(ds.kFold, 1);

                for fold=1:ds.kFold
                    trainIndices = (xindices ~= fold);
                    trainSetRowCount=sum(trainIndices);

                    subIndices = crossvalind('Kfold', trainSetRowCount , ds.subkFold);

                    crossValSubIndices{fold}=subIndices;

                end

                cvIndices{run, 2}=crossValSubIndices;

            end

            save(fileName, 'cvIndices')

            disp(['Completed: ', fileName ])

        end


        %% split

        function [trainData, testData, rowCount] = splitDataTT(ds, run, fold)

            iindices=ds.indices{run};

            testIndices = (iindices == fold);
            trainIndices = ~testIndices;

            trainData=ds.dataSet.data(trainIndices,:);
            testData=ds.dataSet.data(testIndices,:);

            rowCount=size(trainData, 1);

        end

        function [subTrainData, subTestData] = splitSubDataTT(ds, run, fold, trainData, subfold)

            isubIndices=ds.foldsSubIndices{run}{fold};

            testIndices = (isubIndices == subfold);
            trainIndices = ~testIndices;

            subTrainData=trainData(trainIndices,:);
            subTestData=trainData(testIndices,:);

        end

        
        
       
        function dataset = get(ds)
            dataset = ds;
        end
        
        function indices = getIndices(ds, run)
            indices = ds.indices{run};
        end
        
        function subindices = getSubIndices(ds, run)
            subindices = ds.foldsSubIndices{run};
        end
        
    end
end

