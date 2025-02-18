classdef modelUWKNN < baseModel


    methods
        function model = modelUWKNN(standardize, distance, k)
           arguments
                standardize logical = false
                distance {mustBeMember(distance,["euclidean", "cityblock"])} = 'euclidean'
                k (1, 1) double =3
            end            
            model@baseModel();

            model.namex='UW-KNN';
            model.name=sprintf('UW-KNN-k[%d]', k);
            model.options.standardize=standardize;
            model.options.distance=distance;
            model.options.k=k;
        end

        function [perfMetrics, modelx] = createBase(model, tableTrainData, tableTestData, optimals)

            [trainDataX, trainDataY, testDataX, testDataY] = model.splitDataXY(tableTrainData, tableTestData);

            if model.options.standardize
                [trainDataX, mu, sigma] = zscore(trainDataX);
                testDataX=(testDataX-mu)./sigma;
            end

            ds=model.activeDS;
            k=model.options.k;

            testLength=size(testDataX, 1);

            predictedY=zeros(testLength, 1);

            distanceInfo=[ds.dataSet.classValues zeros(ds.dataSet.classCount, 2)];

            for row=1:testLength

                distances=dist(trainDataX, testDataX(row, :)');

                [sortedDistances, sortedIndices]=sortrows(distances);
                topSortedDistances=sortedDistances(1:k);
                topSortedIndices=sortedIndices(1:k, :);

                topSortedLabels=trainDataY(topSortedIndices);
               
                distanceInfo(:, 2:end)=0;
                for i=1:k
                    indx=topSortedLabels(i);
                    distance=topSortedDistances(i);
                    
                    neww=distance/i;


                    distClassCount=distanceInfo(indx, 2);
                    distSum=distanceInfo(indx, 3);

                    distClassCount=distClassCount+1;

                    distSum=distSum+neww;

                    distanceInfo(indx, 2:end)=[distClassCount distSum];

                end

                indx=distanceInfo(:, 2)>0;

                reducedDistanceInfo=sortrows(distanceInfo(indx, :), 3, 'descend');

                predictedY(row)=reducedDistanceInfo(1, 1);

            end

            perfMetrics = model.getPerfMetricsC(testDataY, predictedY);

            modelx=[];

        end


    end

end



