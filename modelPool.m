classdef modelPool < handle
    
    properties
        models={};
        modelCount=0;
        dspool

        runStart=0
        runEnd=0
    end
    
    methods
        
        function mpool=modelPool(dspool)
            disp('Models are creating...')

            mpool.dspool=dspool;

            mpool.models={};
            mpool.modelCount=0;
        end

        function count=add(mpool, model)
            mpool.modelCount=mpool.modelCount+1;
            mpool.models{mpool.modelCount}=model;

            count=mpool.modelCount;
        end    

        function modelnames=getModelNames(mpool)
            modelnames=cell(1, mpool.modelCount);
            for i=1: mpool.modelCount
                modelnames{i}=mpool.models{i}.namex;
            end

        end


        function done=createModels(mpool, runStart, runEnd)

            for d=1:mpool.dspool.dataSetCount
                ds=mpool.dspool.dataSets{d};

                for m=1:mpool.modelCount
                    model=mpool.models{m};

                    model.dataSetOrder=d;
                    model.modelOrder=m;

                    startTime=tic;

                    disp(['#DataSet: ', ds.dataSet.name]);
                    disp(['#StartDateTime: ', datestr(datetime('now'))]);

                    for o=1:model.optimizerCount

                        optimizer=model.optimizers{o};
                        model.optimizerOrder=o;

                        for run=runStart:runEnd

                            model.activeRunStart=runStart;
                            model.activeRunEnd=runEnd;


                            model.start(ds, run, optimizer);
                            
                        end
                        

                        if model.l0ModelCount>0

                            for l=1:model.l0ModelCount

                                l0model=model.l0Models{l};

                                l0model.print();
                                l0model.save();

                            end

                        end

                        model.print();
                        model.save();

                    end

                    execTimeInMinutes=round(toc(startTime)/60, 2);
                    execTimeInHours=round(execTimeInMinutes/60, 2);

                    disp(['THE END - ', num2str(execTimeInMinutes), ' m / ', num2str(execTimeInHours), ' h']);
                    disp(['#EndDateTime: ', datestr(datetime('now'))]);
                    disp('######################################################################################################################');
                    disp('######################################################################################################################');


                    %model.runAll(ds, runStart, runEnd);
                end
            end

            done=true;
        end
       
    end
end

