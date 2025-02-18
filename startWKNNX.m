
clc;
clear all;
close all;
format shortG

kFold=10;
subkFold=5;
runs=30;
runStart=1; runEnd=3;

krange=3:2:5;

%% dataset pool

dspool=dataSetPool('WKNN', runs, kFold, subkFold);


%% two-class

dspool.addC('AlgerianForestFires_244_13_2');
% dspool.addC('BloodTransfusionService_748_4_2');
% dspool.addC('BreastCancerWisconsin_683_9_2');
% dspool.addC('Diabetes_2000_8_2');
% dspool.addC('DiabeticRetinopathyDebrecen_1151_19_2');
% dspool.addC('HabermansSurvival_306_3_2');
% dspool.addC('Ionosphere_351_34_2');
% dspool.addC('MammographicMass_830_5_2');
% dspool.addC('PimaIndianDiabetes_768_8_2');
dspool.addC('StatlogHeart_270_13_2');


%% multi-class

% dspool.addC('BalanceScale_625_4_3');
% dspool.addC('HayesRoth_160_4_3');
dspool.addC('Iris_150_4_3');
% dspool.addC('MaternalHealthRisk_1014_6_3');
dspool.addC('Seeds_210_7_3');
% dspool.addC('TeachingAssistantEvalution_151_5_3');
% dspool.addC('WebsitePhishing_1353_9_3');
% dspool.addC('Wine_178_13_3');
% dspool.addC('Lymphography_148_18_4');
% dspool.addC('Drug_200_5_5');
% dspool.addC('BMI_500_3_6');
% dspool.addC('Dermatology_358_34_6');
% dspool.addC('GlassIdentification_214_9_7');
% dspool.addC('Zoo_101_16_7');
% dspool.addC('Ecoli_336_7_8');
%dspool.addC('ConnectionistBench_990_12_11');


%dspool.addC('ImageSegmentation_2310_19_7');
%dspool.addC('Landsat_Satellite_6435_36_7');
%dspool.addC('Letter_20000_16_26');
%dspool.addC('OptDigits_5620_64_10');
%dspool.addC('Vehicle_846_18_4');


%% model pool

mpool=modelPool(dspool); 

threshold=hyperParam('threshold', [0.01 10], 'real', 'none');
w1=hyperParam('w1', [eps 1], 'real', 'none');
w2=hyperParam('w2', [eps 1], 'real', 'none');


for k=krange

    %% model XHMAKNN
    hmaknn=modelXHMAKNN(false, 'euclidean', 'HM', k);
    hmaknn.addHP2(threshold);
    hmaknn.addBO(36, true);
    
    mpool.add(hmaknn);
    
    
    nwhmknn=modelXHMAKNN(false,'euclidean', 'NWHM', k);
    nwhmknn.addHP2(threshold);
    nwhmknn.addHP2(w1);
    nwhmknn.addBO(36, true);
    
    mpool.add(nwhmknn);

    %% model KNN
    knn=modelKNN(false, 'euclidean', 'equal', k);
    knn.addEO();
    mpool.add(knn);

    %% model WKNNv0
    wknnv0=modelWKNN(false,  'euclidean', 'v0', k);
    wknnv0.addEO();
    mpool.add(wknnv0);

    %% model WKNNv1
    wknnv1=modelWKNN(false,  'euclidean', 'v1', k);
    wknnv1.addEO();
    mpool.add(wknnv1);

    %% model WKNNv2
    wknnv2=modelWKNN(false,  'euclidean', 'v2', k);
    wknnv2.addEO();
    mpool.add(wknnv2);

    %% model UWKNN
    uwknn=modelUWKNN(false,  'euclidean', k);
    uwknn.addEO();
    mpool.add(uwknn);

end


%% Run Model Pool

mpool.createModels(runStart, runEnd);


resultsSummary(runStart, runEnd, krange, dspool, mpool);










