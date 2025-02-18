classdef modelXHMAKNN < baseModel

   
    methods
        function model = modelXHMAKNN(standardize, distance, version, k)
           arguments
                standardize logical = false
                distance {mustBeMember(distance,["euclidean", "cityblock"])} = 'euclidean'
                version {mustBeMember(version,["HM", "WHM", "NWHM"])} = 'HM'
                k (1,1) double=3
            end    
            model@baseModel();
           
            
            model.namex=sprintf('%sA-KNN', version);
            model.name=sprintf('%sA-KNN-k[%d]', version, k);
            model.options.standardize=standardize;   
            model.options.distance=distance;  
            model.options.version=version;
            model.options.k=k;
            
        end

        function [perfMetrics, modelx] = createBase(model, tableTrainData, tableTestData, optimals)

            [trainDataX, trainDataY, testDataX, testDataY] = model.splitDataXY(tableTrainData, tableTestData);

            if model.options.standardize
                [trainDataX, mu, sigma] = zscore(trainDataX);
                testDataX=(testDataX-mu)./sigma;
            end
           
            ds=model.activeDS;

            if strcmp(model.options.version,'HM')
                optimals.w1=1; 
                optimals.w2=1;
            elseif strcmp(model.options.version,'NWHM')
                optimals.w2=1-optimals.w1;
            end            
            
            testLength=size(testDataX, 1);
            kmax=min(model.options.k+25, size(trainDataX, 1));
            
            info=[ds.dataSet.classValues zeros(ds.dataSet.classCount, 3)];

            predictedY=zeros(testLength, 1);
            for row=1:testLength
                k=model.options.k;
                
                distances=dist(trainDataX, testDataX(row, :)');
               
                [sortedDistances, sortedIndices]=sortrows(distances);

                while true

                    topSortedDistances=sortedDistances(1:k);
                    topSortedIndices=sortedIndices(1:k, :);

                    topSortedLabels=trainDataY(topSortedIndices);
                    
                    info(:, 2:end)=0;

                    for idx=1:k
                        indx=topSortedLabels(idx);
                        distance=topSortedDistances(idx);

                        distClassCount=info(indx, 2);
                        distSum=info(indx, 3);

                        distClassCount=distClassCount+1;
                        distSum=distSum+distance;
                        
                        distInvClassCount=1/distClassCount;
                        distAvg=((distSum/distClassCount)+eps);                       
                        
                        distX = (optimals.w1 + optimals.w2) / ( optimals.w1/distInvClassCount + optimals.w2/distAvg );

                        info(indx, 2:end)=[distClassCount distSum distX];
                        
                    end

                    indx=info(:, 2)>0;

                    reducedInfo=info(indx, :);
                    reducedInfo=sortrows(reducedInfo, size(reducedInfo, 2), 'ascend');
                    
                    activeClassCount=size(reducedInfo, 1);

                    isset=true;
                    if activeClassCount>1

                        percentageDistX=abs(reducedInfo(2, end)-reducedInfo(1, end))/reducedInfo(1, end)*100;

                        if percentageDistX < optimals.threshold && k < kmax
                            k=k+1; isset=false;
                        end

                    end

                    if isset
                        predictedY(row)=reducedInfo(1, 1);
                        break
                    end

                end

            end

            perfMetrics = model.getPerfMetricsC(testDataY, predictedY);

            modelx=[];

        end


    end
    
end

