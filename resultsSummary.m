function resultsSummary(runStart, runEnd, krange, dspool, mpool)

    dscount=dspool.dataSetCount;
    allmcount=mpool.modelCount;
    kcount=length(krange);
    mcount=allmcount/kcount;

    runs=runEnd-runStart+1;

    metricnames={'ACC', 'FSCORE', 'PRE', 'RECALL', 'SPE'};

    mnames=cell(1, mcount);
    dsnames=cell(1, dscount);

    runsResult=struct();

    for mn=1:numel(metricnames)
        metricname=metricnames{mn};

        disp(['Calculating netric ' metricname '...'])

        dsResults=cell(dscount, 2);
        dsBestRunsResults=cell(dscount, 2);

        for dsorder=1:dscount
            order=1;
            ds=dspool.dataSets{dsorder};
        
            dsname=ds.dataSet.name;
            dsnames{dsorder}=dsname;


            disp(['Calculating metric for ' dsname '...'])
        
            results=zeros(kcount, 2*mcount+1);
            runsResults=cell(kcount, mcount);

        
            idx=0;
            for i=1:kcount
                k=krange(i);
        
                results(i, 1)=k;
        
                for m=1: mcount
        
                    idx=idx+1;
        
                    model=mpool.models{idx};
    
                    if dsorder==1 && i==1
                        mnames{m}=model.namex;
                    end
        
                    for o=1:model.optimizerCount
                        optimizer=model.optimizers{o};
        
                        fileName=sprintf('x[%d-%d]-[%d]%s-[%d]%s-[%d]%s.mat', ...
                            runStart, runEnd, dsorder, dsname, order, model.name, o, optimizer.description);
        
                        load(fileName, 'perfInfo')
    
                        metricPerf=perfInfo.RunsAvgPerf.(metricname);
                        results(i, 1+m)=metricPerf(1);
                        results(i, 1+mcount+m)=metricPerf(2);

                        runsResults{i,m}=perfInfo.RunsPerf.(metricname);
        
                        order=order+1;
        
                    end
        
                end
    
               
            end

            if dsorder==1
                kmnames=strcat("k", mnames);
                stdmnames=strcat("std",mnames);

                bestResults = table('Size',[dscount 3*mcount+1],'VariableTypes',["string" repmat("double", 1, 3*mcount) ],'VariableNames',["DataSet" mnames stdmnames kmnames ]);
                bestRunsResults=table('Size',[runs mcount],'VariableTypes',repmat("double", 1, mcount),'VariableNames',mnames);
                ranks=table('Size',[dscount 1+mcount],'VariableTypes',["string" repmat("double", 1, mcount) ],'VariableNames',["DataSet" mnames]);
            end

            bestResults.("DataSet")(dsorder)=dsname;
            ranks.("DataSet")(dsorder)=dsname;
            
            dsBestRunsResults{dsorder, 1}=dsname;
            dsResults{dsorder, 1}=dsname;

            dsResults{dsorder, 2}=array2table(results(:, 1:mcount+1), "VariableNames", ["k", mnames]);


            [~,indx]=max(results(:,1+1:1+mcount));
            for m=1: mcount
                mname=mnames{m};
        
                bestK=results(indx(m), 1);
    
                bestAcc=results(indx(m), 1+m) ;
                bestStd=results(indx(m), 1+mcount+m) ;

                bestRunsResults.(mname)=runsResults{indx(m), m};
                
                bestResults.(mname)(dsorder)=bestAcc;
                bestResults.(stdmnames{m})(dsorder)=bestStd;
                bestResults.(kmnames{m})(dsorder)=bestK;
            end

            dsBestRunsResults{dsorder, 2}=bestRunsResults;
            
            [~,~,stats]=friedman(100-bestRunsResults.Variables,1, "off");
            ranks{dsorder,2:end}=stats.meanranks;

        end
        
        bestResultsbyMetric=zeros(dscount, mcount);
        for m=1:mcount
            mname=mnames{m};
            kmname=strcat("k", mname);
            stdmname=strcat("std",mname);

            bestResultsbyMetric(:, m)=bestResults.(mname);

            bestResults=mergevars(bestResults, [mname stdmname kmname ], "NewVariableName", mname);
        end

        disp(bestResults)

        bestResultsMean=array2table(mean(bestResultsbyMetric), "VariableNames",mnames );


        ranksMean=array2table(mean(ranks{:, 2:end}),"VariableNames",mnames);

        runsResult.(metricname).bestResults=bestResults;
        runsResult.(metricname).bestResultsMean=bestResultsMean;
        runsResult.(metricname).ranks=ranks;
        runsResult.(metricname).ranksMean=ranksMean;
        runsResult.(metricname).dsResults=dsResults;
        runsResult.(metricname).dsBestRunResults=dsBestRunsResults;
        
        
    end

    runsResult.methods=mnames;
    runsResult.dataSets=dsnames;

    save("xr-all-results","runsResult");

end




















% function resultsSummary(runStart, runEnd, krange, dspool, mpool)
% 
%     % dsnames={'Wine_178_13_3', 'GlassIdentification_214_9_7'};
%     % mnames={'HMA-KNN', 'WHMA-KNN', 'NWHMA-KNN'};
%     % onames={'BO-MaxEval[30]', 'BO-MaxEval[30]', 'BO-MaxEval[30]'};
%     
%     %krange=2:4;
% 
%     dscount=dspool.dataSetCount;
%     mcount=mpool.modelCount;
%     mcount=mcount/dscount;
%     mnames=mpool.getModelNames();
%     mnames=mnames{1,1:mcount};
%     
%     sz = [dscount 2*mcount+1];
%     varTypes = ["string" repmat("double", 1, mcount) repmat("double", 1, mcount)];
%     varNames = ["DataSet" mnames strcat(mnames, "k")];
%     bestResults = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames);
%     
%     for dsorder=1:dscount
%         order=1;
% 
%         ds=dspool.dataSets{dsorder};
%     
%         dsname=ds.dataSet.name;
%     
%         klen=length(krange);
% 
%         results=zeros(klen, mcount+1); %bakalım
%     
%         for i=1:klen
%             k=krange(i);
%     
%             results(i, 1)=k;
%     
%             for m=1: mcount
% 
%                 model=mpool.models{m};
%     
%                 mname=mnames{m};
%                 
%                 %oname=onames{m};
%                 %onames=model.getOptimizerNames();
% 
%                 for o=1:model.optimizerCount
% 
%                     oname=model.optimizers{o}.description;
% 
%                     fileName=sprintf('x[%d-%d]-[%d]%s-[%d]%s-[%d]-[%d]%s.mat', runStart, runEnd, dsorder, dsname, order, mname, k, oname);
%         
%                     load(fileName, 'perfInfo')
%         
%                     
%                     results(i, m+1)=perfInfo.RunsAvgPerf.ACC(1);
%         
%                     order=order+1;
% 
%                 end
%             end
%     
%         end
%     
%         [~,indx]=max(results(:,2:end));
%     
%         bestResults.("DataSet")(dsorder)=dsname;
%     
%     
%         for m=1: numel(mnames)
%             mname=mnames{m};
%     
%             bestAcc=results(indx(m), m+1) ;
%             bestK=results(indx(m), 1);
% 
%             bestResults.(mname)(dsorder)=bestAcc;
%             bestResults.(strcat(mname,"k"))(dsorder)=bestK;
%         end
%     
%     end
%     
%     for m=1: numel(mnames)
%         mname=mnames{m};
%         mnamek=strcat(mname, "k");
%     
%         bestResults=mergevars(bestResults, [mname mnamek], "NewVariableName", mname);
%     end
%     
%     disp(bestResults)
% 
% end