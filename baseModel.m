classdef baseModel < handle

    properties
        name
        namex
        options

        metricNames

        params
        paramCount=0

        optimizers
        optimizerCount=0

        details
        fileName

        dataSetOrder
        modelOrder
        modelOrderStr
        optimizerOrder


        iterationCount=0;
        iterationStart=0;
        iterationEnd=0;

        foldsOptInfo={};
        foldsPerfInfo={};

        runsPerf;
        runsAvgPerf;  


        activeDS
        activeRun
        activeRunStart
        activeRunEnd

        activeCVModels


        l0Models
        l0ModelCount

        hasMasterModel
        masterModel

    end

    methods

        function model = baseModel()
            model.optimizers=baseOptimizer.empty(0);
            model.optimizerCount=0;

            model.params=hyperParam.empty(0);
            model.paramCount=0;
            
            model.l0Models=baseModel.empty(0,1);
            model.l0ModelCount=0;

            model.hasMasterModel=false;
        end

        function count=addL0Model(model, l0model)

            if model.l0ModelCount==0
                model.name=sprintf('%s-SE', model.name);
            end

            l0model.name=sprintf('%s-L0', l0model.name);
            
            model.l0ModelCount=model.l0ModelCount+1;
            model.l0Models{model.l0ModelCount}=l0model;
            count=model.l0ModelCount;

            l0model.hasMasterModel=true;
            l0model.masterModel=model;

        end

        %% PARAMS

        function count=addHP(model, name, range, type, transform, gridSize, step, optimize)
            arguments
                model
                name (1, :) char
                range (1, :) double
                type {mustBeMember(type,["real", "integer", "categorical"])} = 'real'
                transform {mustBeMember(transform,["none", "log"])} = 'none'
                gridSize (1, 1) double=0
                step (1, 1) double=0
                optimize logical = true
            end

            hp=hyperParam(name, range, type, transform, gridSize, step, optimize);
            count=model.addHP2(hp);

        end

        function count=addHP2(model, hp)
            arguments
                model
                hp hyperParam
            end

            model.paramCount = model.paramCount + 1;
            model.params(1, model.paramCount)=hp;
            count=model.paramCount;
        end

        
        %% OPT

        function addEO(model)
            eo=optimizerEmpty(hyperParam.empty(0));

            model.addOptimizer(eo);
        end

        function addGS(model)
            gs=optimizerGS(model.params);

            model.addOptimizer(gs);
        end

        function addBO(model, maxEvaluations, useParallel)
            bo=optimizerBO(model.params, maxEvaluations, useParallel);

            model.addOptimizer(bo);
        end

        function addPSO(model, maxIterations, swarmSize, useParallel)
            pso=optimizerPSO(model.params, maxIterations, swarmSize, useParallel);

            model.addOptimizer(pso);
        end

        
        function count = addOptimizer(model, optimizer)
            model.optimizerCount=model.optimizerCount+1;

            model.optimizers{model.optimizerCount}=optimizer;

            count=model.optimizerCount;
        end


        function optimizernames=getOptimizerNames(model)
            optimizernames=cell(1, model.optimizerCount);
            for i=1: model.optimizerCount
                optimizernames{i}=model.optimizers{i}.name;
            end

        end


        %% models

        function [perfMetrics, modelX] = create(model, tableTrainData, tableTestData, optimals)

            [perfMetrics, modelX] = model.createBase(tableTrainData, tableTestData, optimals);

        end

        function cost = createCost(model, subTrainData, subTestData, params, paramNames)
            if istable(params) == false
                params=array2table(params, 'VariableNames', paramNames);
            end

            r = model.createBase(subTrainData, subTestData, params);

            cost=r.cost;
        end  


        function [foldsPerfInfo, foldsOptInfo] = start(model, ds, run, optimizer)

            model.activeDS=ds;
            model.activeRun=run;
            model.metricNames=model.getPerfMetricsNames(ds.dataSet.isClassification);

            disp('######################################################################################################################');
            disp(['#Run: ', num2str(run-model.activeRunStart+1), '/', num2str(model.activeRunEnd-model.activeRunStart+1), ' - [', num2str(run), '][',num2str(model.activeRunStart) , ', ', num2str(model.activeRunEnd) , ']']);

            [foldsPerfInfo, foldsOptInfo]=model.crossValidateModels(ds, run, optimizer);
            model.Add(run, foldsPerfInfo, foldsOptInfo);

            disp('######################################################################################################################');

        end



        function [foldsPerfInfo, foldsOptInfo] = crossValidateModels(model, ds, run, optimizer)
            model.details=[' #Run: ', num2str(run), ' #DataSet: ', ds.dataSet.name, ' #Model: ', model.name, ' #Optimizer: ', optimizer.description];

            if model.hasMasterModel==true
                model.modelOrderStr=sprintf('[%d][%d]', model.masterModel.modelOrder, model.modelOrder);
            else
                model.modelOrderStr=sprintf('[%d]', model.modelOrder);
            end

            model.fileName=sprintf('[%d]%s-%s%s-[%d]%s.mat', model.dataSetOrder, ds.dataSet.name, model.modelOrderStr, model.name, model.optimizerOrder, optimizer.description);  

            paramNames=optimizer.getHPNames();
            variableNames=['Fold', model.metricNames, 'ExecTime', 'CreatedModel', 'minERR', paramNames];

            foldsPerf=zeros(ds.kFold, size(variableNames, 2));
            foldsOptInfo=cell(ds.kFold, 1);

            disp(model.details)
            disp([' #DateTime: ', datestr(datetime('now'))]);

            

            if model.l0ModelCount>0

                for m=1:model.l0ModelCount

                    l0model=model.l0Models{m};

                    l0model.dataSetOrder=model.dataSetOrder;
                    l0model.modelOrder=m;

                    for o=1:l0model.optimizerCount
                        l0model.optimizerOrder=o;

                        l0model.runStart=model.activeRunStart;
                        l0model.runEnd=model.activeRunEnd;

                        l0optimizer=l0model.optimizers{o};
                        l0model.start(ds, run, l0optimizer);

                    end

                end

            end

            
            model.activeCVModels=cell(ds.kFold,1);

            for fold=1:ds.kFold
                disp(['  #Fold: ', num2str(fold), '/', num2str(ds.kFold), ' #Run: ', num2str(run), ' #DataSet: ', ds.dataSet.name, ' #Model: ', model.name])

                [trainData, testData]=ds.splitDataTT(run, fold);

                if model.l0ModelCount>0

                    [trainX, trainY, testX, testY] = model.splitDataXY(trainData, testData);

                    lTrainData=size(trainData, 1);
                    lTestData=size(testData, 1);

                    newTrainX=zeros(lTrainData,model.l0ModelCount);
                    newTestX=zeros(lTestData,model.l0ModelCount);

                    for m=1:model.l0ModelCount
                        xl0model=model.l0Models{m};
                        xcvmodel=xl0model.activeCVModels{fold};

                        newTrainX(:, m)=xl0model.startPredict(xcvmodel, trainX);
                        newTestX(:, m)=xl0model.startPredict(xcvmodel, testX);
                    end

                    trainData=[trainX newTrainX trainY];
                    testData=[testX newTestX testY];
                    
                end

                costFunction = @(xparams) model.crossValidateSubModels(ds, run, fold, trainData, xparams, paramNames);

                [optimals, execTime, createdModel, optInfo, minError]  = optimizer.optFunction(costFunction);

                [perf, cvmodel] = model.create(trainData, testData, optimals);

                model.activeCVModels{fold}=cvmodel;
                
                execTime=round(execTime/60, 3);

                foldsPerf(fold,:) = [fold perf.metrics execTime createdModel minError table2array(optimals)];

                foldsOptInfo{fold, 1}=optInfo;

                disp(['   #Fold: ', num2str(fold), '/', num2str(ds.kFold), ' #COST: ', num2str(perf.cost)]);

            end

            foldsPerfInfo=array2table(foldsPerf, 'VariableNames', variableNames);

        end

        function cost = crossValidateSubModels(model, ds, run, fold, trainData, params, paramNames)

            costs=zeros(ds.subkFold, 1);
            for sfold=1:ds.subkFold

                [subTrainData, subTestData] = ds.splitSubDataTT(run, fold, trainData, sfold);
                costs(sfold)= model.createCost(subTrainData, subTestData, params, paramNames);

            end

            cost=mean(costs);

        end


        function [trainDataX, trainDataY, testDataX, testDataY] = splitDataXY(~, tableTrainData, tableTestData, isModelNN)
            arguments
                ~
                tableTrainData
                tableTestData
                isModelNN logical = false
            end

            if istable(tableTrainData)
                trainData=table2array(tableTrainData);
            else
                trainData=tableTrainData;
            end

            if istable(tableTestData)
                testData=table2array(tableTestData);
            else
                testData=tableTestData;
            end

    
            trainDataX=trainData(:,1:end-1);
            trainDataY=trainData(:,end);
    
            testDataX=testData(:,1:end-1);
            testDataY=testData(:,end);
           
            if isModelNN
                trainDataX=trainDataX';
                trainDataY=trainDataY';
    
                testDataX=testDataX';
                testDataY=testDataY';
            end

        end

        %% performance

        function names = getPerfMetricsNames(~, isClassification)

            if isClassification
                %names={'ACC', 'TP', 'FP', 'IC'};
                %r.metrics=[r.accuracy r.fscore r.precision r.recall r.specificity];
                names={'ACC', 'FSCORE', 'PRE', 'RECALL', 'SPE'};
            else
                names={'MSE', 'RMSE', 'MAE' ,'MAPE', 'R'};
            end

        end

        %% 
        function metrics = multiclass_metrics_common(~, confmat)

            N = size(confmat,1);
            precision = zeros(1,N);
            recall = zeros(1,N);
            specificity = zeros(1,N);
            accuracy = zeros(1,N);
            fscore = zeros(1,N);
            if size(confmat,1) > 2
                for i = 1:size(confmat,1)
                    TP = confmat(i,i);
                    FN = sum(confmat(i,:))-confmat(i,i);
                    FP = sum(confmat(:,i))-confmat(i,i);
                    TN = sum(confmat(:))-TP-FP-FN;
                    precision(:,i)   = TP / (TP+FP); % positive predictive value (PPV)
                    recall(:,i)      = TP / (TP+FN); % true positive rate (TPR), sensitivity
                    if ((TN / (TN+FP)) > 1)
                        specificity(:,i) = 1;
                    elseif ((TN / (TN+FP)) < 0)
                        specificity(:,i) = 0;
                    else
                        specificity(:,i) = TN / (TN+FP); % (SPC) or true negative rate
                    end
                    accuracy(:,i)    = (TP)/(TP+TN+FP+FN); % Accuracy
                    fscore(:,i)     = (2*TP) /(2*TP + FP + FN);
                end

                % Remove junks
                stats = [precision', recall', fscore', accuracy', specificity'];
                stats(any(isinf(stats),2),:) = [];
                stats(any(isnan(stats),2),:) = [];
                N = size(stats,1);

                % Compute averages
                accuracy  = sum(stats(:,4));
                precision = mean(stats(:,1));
                recall    = mean(stats(:,2));
                specificity = mean(specificity);
                fscore = mean(stats(:,3));
            else
                TP = confmat(1, 1);
                FP = confmat(2, 1);
                FN = confmat(1, 2);
                TN = confmat(2,2);
                precision = TP / (TP+FP); % positive predictive value (PPV)
                recall    = TP / (TP+FN); % true positive rate (TPR), sensitivity
                if ((TN / (TN+FP)) > 1)
                    specificity = 1;
                elseif ((TN / (TN+FP)) < 0)
                    specificity = 0;
                else
                    specificity = TN / (TN+FP); % (SPC) or true negative rate
                end
                accuracy = (TP+TN)/(TP+TN+FP+FN); % Accuracy
                fscore  = 2*TP /(2*TP + FP + FN);

            end
            
            metrics.precision = precision*100;
            metrics.recall = recall*100;
            metrics.accuracy = accuracy*100;
            metrics.specificity = specificity*100;
            metrics.fscore = fscore*100;

        end

        function r = getPerfMetricsC(model, y, p)

           c=confusionmat(y, p);

           r=model.multiclass_metrics_common(c);

           r.cost=100.0-r.accuracy;
            
           r.metrics=[r.accuracy r.fscore r.precision r.recall r.specificity];

        end     

        function r = getPerfMetricsR(~, y, p)

            e=(y-p);

            r.mse=round( mean(e.^2) ,3);
            r.rmse=round( sqrt(r.mse) ,3);

            r.mape=round( mean(abs(e./y))*100 ,3);

            r.mae=round( mean(abs(e)) ,3);

            r.R2=1-(sum(e.^2)/sum((y-mean(y)).^2));

            r.R=round( sqrt(r.R2) ,3);

            r.cost=r.mse;
            r.metrics=[r.mse r.rmse r.mae r.mape r.R];

        end        

        

        %% print and save


        function count=Add(model, run, foldsPerfInfox, foldsOptInfox)
            if model.iterationCount==0
                model.iterationStart=run;
            end
            model.iterationEnd=run;
            model.iterationCount=model.iterationCount+1;

            model.foldsPerfInfo{model.iterationCount, 1}=foldsPerfInfox;
            model.foldsOptInfo{model.iterationCount, 1}=foldsOptInfox;

            Run=run;

            ExecTime = round(mean(foldsPerfInfox.ExecTime), 3);
            CreatedModel = max(foldsPerfInfox.CreatedModel);
            minERR = round(mean(foldsPerfInfox.minERR), 3);

            foldsAvgPerf = table(Run, ExecTime, CreatedModel, minERR);


            for i=numel(model.metricNames):-1:1
                metricName=string(model.metricNames(i));
                metric=round(mean(foldsPerfInfox.(metricName)), 3);
                
                foldsAvgPerf=addvars(foldsAvgPerf, metric, 'NewVariableNames', metricName, 'After','Run');
            end

            model.foldsPerfInfo{model.iterationCount, 2}=foldsAvgPerf;

            disp(model.details)
            disp(' #---------------------------------------------------------------------------------')
            disp(foldsPerfInfox)
            disp(foldsAvgPerf)

            %------------------------------------
            if model.iterationCount==1
                model.runsPerf=foldsAvgPerf;
            else
                model.runsPerf=[model.runsPerf; foldsAvgPerf];
            end


            if (model.activeRunEnd-model.activeRunStart+1)==model.iterationCount

                Run=model.iterationCount;
    
                ExecTime = round(mean(model.runsPerf.ExecTime), 3);
                CreatedModel=max(model.runsPerf.CreatedModel);
                minERR = round(mean(model.runsPerf.minERR), 3);
    
                model.runsAvgPerf = table(Run, ExecTime, CreatedModel, minERR);
    
                for i=numel(model.metricNames):-1:1
                    metricName=string(model.metricNames(i));
                    metric=[round(mean(model.runsPerf.(metricName)), 3) round(std(model.runsPerf.(metricName)), 3)];
                    
                    model.runsAvgPerf=addvars(model.runsAvgPerf, metric, 'NewVariableNames', metricName, 'After','Run');
                end

            end

            count=model.iterationCount;

        end

        function printed = print(model)

            disp(model.details);

            disp(model.runsPerf);
            disp(model.runsAvgPerf);

            disp('#---------------------------------------------------------------------------------')

            printed=true;

        end

        function perfInfo = save(model)

            perfInfo=struct();
            perfInfo.RunRange=[model.iterationStart, model.iterationEnd];
            perfInfo.FoldsPerfInfo=model.foldsPerfInfo;
            perfInfo.FoldsOptInfo=model.foldsOptInfo;
            perfInfo.RunsPerf=model.runsPerf;
            perfInfo.RunsAvgPerf=model.runsAvgPerf;
            perfInfo.Options=model.options;

            model.fileName=sprintf('x[%d-%d]-%s',  model.iterationStart, model.iterationEnd, model.fileName);
            disp(model.fileName)
            save(model.fileName, 'perfInfo');

            model.iterationCount=0;
            model.iterationStart=0;
            model.iterationEnd=0;

            model.foldsOptInfo={};
            model.foldsPerfInfo={};

            model.runsPerf=table;
            model.runsAvgPerf=table;
            model.fileName='';
        end
   
       
    end

     
end


%         function runAll(model, ds, runStart, runEnd)
% 
%             startTime=tic;
% 
%             disp(['#DataSet: ', ds.dataSet.name]);
%             disp(['#StartDateTime: ', datestr(datetime('now'))]);
% 
%             for i=1:model.optimizerCount
% 
%                 optimizer=model.optimizers{i};
% 
%                 model.startRun(ds, optimizer, runStart, runEnd);
% 
%             end
% 
%             execTimeInMinutes=round(toc(startTime)/60, 2);
%             execTimeInHours=round(execTimeInMinutes/60, 2);
% 
%             disp(['THE END - ', num2str(execTimeInMinutes), ' m / ', num2str(execTimeInHours), ' h']);
%             disp(['#EndDateTime: ', datestr(datetime('now'))]);
%             disp('######################################################################################################################');
%             disp('######################################################################################################################');
% 
% 
%         end


%         function [foldsPerfInfo, foldsOptInfo] = startRun(model, ds, optimizer, runStart, runEnd)
% 
%             model.activeDS=ds;
% 
%             for run=runStart:runEnd
% 
%                 disp('######################################################################################################################');
%                 disp(['#Run: ', num2str(run-runStart+1), '/', num2str(runEnd-runStart+1), ' - [', num2str(run), '][',num2str(runStart) , ', ', num2str(runEnd) , ']']);
% 
%                 [foldsPerfInfo, foldsOptInfo]=model.crossValidateModels(run, ds, optimizer);
% 
%                 model.Add(run, foldsPerfInfo, foldsOptInfo);
% 
%                 disp('######################################################################################################################');
% 
%             end
% 
%             model.print();
%             model.save();
% 
%         end



