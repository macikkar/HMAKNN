classdef modelWKNN < baseModel


    methods
        function model = modelWKNN(standardize, distance, version, k)
           arguments
                standardize logical = false
                distance {mustBeMember(distance,["euclidean", "cityblock"])} = 'euclidean'
                version {mustBeMember(version,["v0", "v1", "v2"])} = 'v0'
                k (1, 1) double =3
            end            
            model@baseModel();

            model.namex=sprintf('W-KNN-%s', version);
            model.name=sprintf('W-KNN-%s-k[%d]', version, k);
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
                    
                    w=1;
                    if topSortedDistances(1)~=topSortedDistances(k)
                        w=(topSortedDistances(k)-distance)/(topSortedDistances(k)-topSortedDistances(1));
                    end

                    wk=1;
                    if strcmp(model.options.version,'v1')
                        wk=1/i;
                    elseif strcmp(model.options.version,'v2')
                        wk=(topSortedDistances(k)+topSortedDistances(1))/(topSortedDistances(k)+distance);
                    end

                    w=wk*w;

                    neww=w*distance;


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



