classdef modelKNN < baseModel

   
    methods
        function model = modelKNN(standardize, distance, distanceWeight, k)
            arguments
                standardize logical = false
                distance {mustBeMember(distance,["euclidean", "cityblock"])} = 'euclidean'
                distanceWeight {mustBeMember(distanceWeight,["equal", "inverse", "squaredinverse"])} = 'equal'
                k (1,1) double = 3
            end
            model@baseModel();
           
            model.namex=sprintf('KNN-%s', distanceWeight);
            model.name=sprintf('KNN-%s-k[%d]', distanceWeight, k);
            model.options.standardize=standardize;       
            model.options.distance=distance;   
            model.options.distanceWeight=distanceWeight;   
            model.options.k=k;
        end
        

        function [perfMetrics, modelx, predictedDataY] = createBase(model, tableTrainData, tableTestData, optimals)

            [trainDataX, trainDataY, testDataX, testDataY] = model.splitDataXY(tableTrainData, tableTestData);
            
            modelx = fitcknn(trainDataX, trainDataY, 'NumNeighbors', model.options.k,...
                'NSMethod', 'exhaustive', 'Distance', model.options.distance,...
                'Standardize', model.options.standardize,...
                'DistanceWeight', model.options.distanceWeight);

            predictedDataY = model.startPredict(modelx, testDataX);

            perfMetrics = model.getPerfMetricsC(testDataY, predictedDataY);

        end

        function predictedY = startPredict(~, mdl, dataX)

            predictedY = predict(mdl, dataX);

        end

    end
    
end

