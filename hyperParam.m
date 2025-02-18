classdef hyperParam

    properties (SetAccess=immutable)
        name=''
        range
        type='real' % 'real' | 'integer' | 'categorical'
        transform='none' % 'none' | 'log'
        gridSize
        step
        optimize=true
        
        values=[]
        intervals=[]
        exponents=[]
        indices=[]
    end
    
    methods
        function hp = hyperParam(name, range, type, transform, gridSize, step, optimize)
            arguments
                name (1, :) char
                range (1, :) double
                type {mustBeMember(type,["real", "integer", "categorical"])} = 'real'
                transform {mustBeMember(transform,["none", "log"])} = 'none'
                gridSize (1, 1) double=0
                step (1, 1) double=0
                optimize logical = true
            end            
            hp.name=name;
            hp.range=range;
            hp.type=type;
            hp.transform=transform;
            hp.gridSize=gridSize;
            hp.step=step;
            hp.optimize=optimize;

            if transform=="log" && gridSize>0
                hp.exponents=linspace(log2(range(1)), log2(range(2)), gridSize);
                hp.values= round(power(2, hp.exponents), 4);
                hp.indices=1:gridSize;
            end

            if transform=="none" 
                if step==0
                    step=1;
                end
                hp.exponents=[];
                hp.values= range(1):step:range(2);
                hp.gridSize=length(hp.values);
                hp.indices=1:hp.gridSize;
            end


        end 


        function variable=getForBO(hp)
            variable=optimizableVariable(hp.name, hp.range , "Type", hp.type ,'Transform', hp.transform, 'Optimize',hp.optimize);
        end
        
    end
end




