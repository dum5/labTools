classdef BiofeedbackSL
    %Class BiofeedbackMD houses metadata and methods to process step length
    %biofeedback trials
    %
    %Properties:
    %
    %   subjectcode = '' string containing subject code, e.g. 'SLP001'
    %   date=''  Date of the experiment, lab date object
    %   day='' string that indicates day1 or day2 testing
    %   sex = '' string designates subject sex e.g. 'f'
    %   dob='' lab date object with date of birth
    %   dominantleg='' string designate dominant leg, e.g. 'r'
    %   dominanthand = '' string designate dominant hand e.g. 'r'
    %   height=[];  cm
    %   weight=[];  kg
    %   age=[];  years
    % 
    %   triallist={};  cell array of trial #'s, filenames, and type of
    %   trial. construct instance with blank cell, can input data using a
    %   method instead of copying and pasting into inputs
    % 
    %   Rtmtarget=[]; right leg step length target as determined by treadmill baseline
    % 
    %   Ltmtarget=[]; left leg step length target as determined by treadmill baseline
    % 
    %   OGsteplength=[]; step length target as determined by over-ground walking
    % 
    %	OGspeed=[]; average speed of subject during the OG trial to determine OG steplength
    % 
    %Methods:       
    % 
    %   AnalyzePerformance(flag) -- computes step length errors for each
    %                               biofeedback trial, 
    %
    %   editTriallist() -- select filenames, edit trial #'s and type and
    %                      category, input num is the # of trials, or rows in the list
    %
    %   saveit() -- saves the instance with filename equal to the ID
    %
    %   comparedays() -- makes bar plots comparing day1 and day2

    
    properties
        subjectcode = ''
        date=''
        day=''
        sex = ''
        dob=''
        dominantleg=''
        dominanthand = ''
        height=[];
        weight=[];
        age=[];
        triallist={};
        Rtmtarget=[];
        Ltmtarget=[];
        OGsteplength=[];
        OGspeed=[];
        datalocation=pwd;
        
        
    end
    
    methods
        %constuctor
        function this=BiofeedbackSL(ID,date,day,sex,dob,dleg,dhand,height,weight,age,triallist,Rtarget,Ltarget,OGsteplength,OGspeed)
        
            if nargin ~= 15
%                 disp('Error, incorrect # of input arguments provided');
                cprintf('err','Error: incorrect # of input arguments provided\n');
            else
                
                if ischar(ID)
                    this.subjectcode=ID;
                else
                    this.subjectcode='';
                    cprintf('err','WARNING: invalid subject ID input, must be a string\n');
                end
                
                if isa(date,'labDate')
                    this.date = date;
                else
                    cprintf('err','WARNING: incorrect experiment date format provided, must be class labDate\n');
                    this.date='';
                end
                
                if isnumeric(day)
                    this.day = day;
                else
                    cprintf('err','WARNING: input for day must be a number\n');
                    this.day='';
                end
                    
                if ischar(sex)
                    this.sex = sex;
                else
                    cprintf('err','WARNING: input for sex must be a string\n');
                    this.sex='';
                end
                
                if isa(dob,'labDate')
                    this.dob=dob;
                else
                    cprintf('err','WARNING: date of birth is not the correct format\n');
                    this.dob=[];
                end
                
                if ischar(dleg)
                    this.dominantleg=dleg;
                else
                    cprintf('err','WARNING: incorrect format for dominant leg input, must be a string\n');
                    this.dominantleg='';
                end
                
                if ischar(dhand)
                    this.dominanthand=dhand;
                else
                    cprintf('err','WARNING: incorrect format for dominant hand input, must be a string\n');
                    this.dominanthand='';
                end
                
                if isnumeric(height)
                    this.height = height;
                else
                    cprintf('err','WARNING: input height is not numeric\n');
                    this.height=[];
                end
                
                if isnumeric(weight)
                    this.weight = weight;
                else
                    cprintf('err','WARNING: input weight is not numeric\n');
                    this.weight=[];
                end
                
                if isa(age,'labDate')
                    this.age = age;
                else
                    cprintf('err','WARNING: input weight is not class labDate\n');
                    this.age=[];
                end
                
                if iscell(triallist)
                    this.triallist=triallist;
                else
                    cprintf('err','WARNING: triallist input is not a cell format.\n');
                    this.triallist={};
                end
                
                if isnumeric(Rtarget)
                    this.Rtmtarget = Rtarget;
                else
                    cprintf('err','WARNING: Right step length target is not numeric type.\n');
                    this.Rtmtarget = [];
                end
                
                if isnumeric(Ltarget)
                    this.Ltmtarget = Ltarget;
                else
                    cprintf('err','WARNING: Left step length target is not numeric type.\n');
                    this.Ltmtarget = [];
                end
                    
                if isnumeric(OGsteplength)
                    this.OGsteplength = OGsteplength;
                else
                    cprintf('err','WARNING: OG step length target is not numeric type.\n');
                    this.OGsteplength = [];
                end
                
                if isnumeric(OGspeed)
                    this.OGspeed = OGspeed;
                else
                    cprintf('err','WARNING: OG speed is not numeric type.\n');
                    this.OGspeed = [];
                end
                
            end

            
            
        end
        
        function []=AnalyzePerformance(this)
            %compute step length error for each trial, uses instance
            %defined target values and the default tolerance of 0.0375 m
            %
            %auto-saves the results

            global rhits
            global lhits
            
            if isempty(this.triallist)
                cprintf('err','WARNING: no trial information available to analyze');
            else
               filename = this.triallist(:,1);

               if iscell(filename)%if more than one file is selected for analysis

                   rhits = {0};
                   lhits = {0};
                   rlqr = {0};
                   llqr = {0};
                   
                   for z = 1:length(filename)
                       tempname = filename{z};
                       if strcmp(tempname(end-5:end-4),'V3')
                           color{z} = 'blue';
                       else
                           color{z} = 'red';
                       end
                       [header,data] = JSONtxt2cell(filename{z});
                       [m,n] = size(data);
                       
                       data2 = unique(data,'rows','stable');%remove duplicate frames
                       data2(:,1) = data2(:,1)-data2(1,1)+1;%set frame # to start at 1
                       for zz = 1:n
                           data3(data2(:,1),zz) = data2(:,zz);
                       end
                       frame = data3(:,1);
                       frame2 = 1:1:data2(end,1);
                       
                       Rz2 = interp1(data2(:,1),data2(:,2),frame2,'linear');
                       Lz2 = interp1(data2(:,1),data2(:,3),frame2,'linear');
                       Rgamma2 = interp1(data2(:,1),data2(:,6),frame2,'linear');
                       Lgamma2 = interp1(data2(:,1),data2(:,7),frame2,'linear');
                       
                       %detect HS
                       for zz = 1:length(Rz2)-1
                           if Rz2(zz) > -25 && Rz2(zz+1) <= -25
                               RHS(zz) = 1;
                           else
                               RHS(zz) = 0;
                           end
                       end
                       [~,trhs] = findpeaks(RHS,'MinPeakDistance',100);
                       RHS = zeros(length(RHS),1);
                       RHS(trhs) = 1;
                       for zz = 1:length(Lz2)-1
                           if Lz2(zz) > -25 && Lz2(zz+1) <= -25
                               LHS(zz) = 1;
                           else
                               LHS(zz) = 0;
                           end
                       end
                       [~,tlhs] = findpeaks(LHS,'MinPeakDistance',100);
                       LHS = zeros(length(LHS),1);
                       LHS(tlhs) = 1;
%                        keyboard
                       %%!!!!!!!!!!!!!!!!!!!!!!!%%!!!!!!!!!!!!!!!!!%%%!!!!!!!!!!!!!!!!
                       %calculate errors
                       tamp = abs(Rgamma2(find(RHS)))'-this.Rtmtarget;
                       tamp2 = abs(Lgamma2(find(LHS)))'-this.Ltmtarget;
                       
                       tamp(abs(tamp)>0.15)=[];%remove spurios errors
                       tamp2(abs(tamp2)>0.15)=[];
                       
                       rhits{z} = tamp;
                       lhits{z} = tamp2;
                       
                       rlqr{z} = iqr(rhits{z});
                       llqr{z} = iqr(lhits{z});
                        clear RHS LHS tamp tamp2
                   end
                   clear z
                   
                   %load triallist to look for categories
                   tlist = this.triallist;
                   
                   train = find(strcmp(tlist(:,4),'training'));%logicals of where training trials are
                   base = find(strcmp(tlist(:,4),'baseline'));
                   adapt = find(strcmp(tlist(:,4),'adaptation'));
                   wash = find(strcmp(tlist(:,4),'washout'));
                   
                   figure(2)
                   hold on
%                    keyboard
                   fill([0 length(cell2mat(rhits(train)')) length(cell2mat(rhits(train)')) 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   fill([length(cell2mat(rhits(train)'))+length(cell2mat(rhits(base)')) length(cell2mat(rhits(train)'))+length(cell2mat(rhits(base)'))+length(cell2mat(rhits(adapt)')) length(cell2mat(rhits(train)'))+length(cell2mat(rhits(base)'))+length(cell2mat(rhits(adapt)')) length(cell2mat(rhits(train)'))+length(cell2mat(rhits(base)'))],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   
                   h = 0;
                   for z = 1:length(filename)
                       figure(2)
                       scatter([1:length(rhits{z})]+h,rhits{z},75,color{z},'fill');
                       plot([h h+length(rhits{z})],[0.0375 0.0375],'k');%tolerance lines
                       plot([h h+length(rhits{z})],[-0.0375 -0.0375],'k');
                       plot([h h+length(rhits{z})],[nanmean(rhits{z})+rlqr{z}/2 nanmean(rhits{z})+rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       plot([h h+length(rhits{z})],[nanmean(rhits{z})-rlqr{z}/2 nanmean(rhits{z})-rlqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       h = h+length(rhits{z});
                   end
                   figure(2)
                   ylim([-0.25 0.25]);
                   xlim([0 h+10]);
                   title('Step Length Error Fast Leg');
                   xlabel('step #');
                   ylabel('Error (m)');

                   figure(3)
                   hold on
                   fill([0 length(cell2mat(lhits(train)')) length(cell2mat(lhits(train)')) 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   fill([length(cell2mat(lhits(train)'))+length(cell2mat(lhits(base)')) length(cell2mat(lhits(train)'))+length(cell2mat(lhits(base)'))+length(cell2mat(lhits(adapt)')) length(cell2mat(lhits(train)'))+length(cell2mat(lhits(base)'))+length(cell2mat(lhits(adapt)')) length(cell2mat(lhits(train)'))+length(cell2mat(lhits(base)'))],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   
                   h = 0;
                   for z = 1:length(filename)
                       figure(3)
                       %         hold on
                       scatter([1:length(lhits{z})]+h,lhits{z},75,color{z},'fill');
                       plot([h h+length(lhits{z})],[0.0375 0.0375],'k');%tolerance lines
                       plot([h h+length(lhits{z})],[-0.0375 -0.0375],'k');
                       plot([h h+length(lhits{z})],[nanmean(lhits{z})+llqr{z}/2 nanmean(lhits{z})+llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       plot([h h+length(lhits{z})],[nanmean(lhits{z})-llqr{z}/2 nanmean(lhits{z})-llqr{z}/2],'Color',[0.5 0 0.5],'LineWidth',2);%tolerance lines
                       h = h+length(lhits{z});
                       %         h = h+length(lhits{z});
                   end
                   figure(3)
                   ylim([-0.25 0.25]);
                   xlim([0 h+10]);
                   title('Step Length Error Slow Leg');
                   xlabel('step #');
                   ylabel('Error (m)');
                   
                   for z=1:length(rhits)
                       temp = rhits{z};
                       temp(abs(temp) > 0.1) = [];
                       meanrhits1(z) = mean(temp(1:3));
                       stdrhits1(z) = std(temp(1:3));
                       meanrhits2(z) = mean(temp(end-2:end));
                       stdrhits2(z) = std(temp(end-2:end));
                   end
                   for z=1:length(lhits)
                       temp = lhits{z};
                       temp(abs(temp) > 0.1) = [];
                       meanlhits1(z) = mean(temp(1:3));
                       stdlhits1(z) = std(temp(1:3));
                       meanlhits2(z) = mean(temp(end-2:end));
                       stdlhits2(z) = std(temp(end-2:end));
                   end
                   
                   
                   figure(5)
                   hold on
                   fill([0 2*length(train)+0.5 2*length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   fill([2*length(train)+0.5+2*length(base) 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+0.5+2*length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   h = 1:2:2*length(meanrhits1);
                   h2 = 2:2:2*length(meanrhits2);
                   errorbar(h,meanrhits1,stdrhits1,'k','LineWidth',1.5);
                   errorbar(h2,meanrhits2,stdrhits2,'k','LineWidth',1.5);
                   plot([0 2*length(meanrhits1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                   plot([0 2*length(meanrhits1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                   %     plot([0 2*length(meanrhits1)+1],[nanmean(rhits{z})+rlqr{z} nanmean(rhits{z})+rlqr{z}]
                   for z = 1:length(h)
                       figure(5)
                       bar(h(z),meanrhits1(z),0.5,'FaceColor',color{z});%color2(z,:));
                       %         plot(h(z),nanmean(rhits{z})+rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                       %         plot(h(z),nanmean(rhits{z})-rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                   end
                   for z=1:length(h2)
                       figure(5)
                       bar(h2(z),meanrhits2(z),0.5,'FaceColor',color{z});%color2(z,:));
                       %         plot(h2(z),nanmean(rhits{z})+rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                       %         plot(h2(z),nanmean(rhits{z})-rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                   end
                   ylim([-0.25 0.25]);
                   title('Fast Leg Errors')
                   ylabel('Error (m)');
                   
                   
                   figure(6)
                   hold on
                   fill([0 2*length(train)+0.5 2*length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   fill([2*length(train)+0.5+2*length(base) 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+0.5+2*length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                   h = 1:2:2*length(meanlhits1);
                   h2 = 2:2:2*length(meanlhits2);
                   errorbar(h,meanlhits1,stdlhits1,'k','LineWidth',1.5);
                   errorbar(h2,meanlhits2,stdlhits2,'k','LineWidth',1.5);
                   plot([0 2*length(meanlhits1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                   plot([0 2*length(meanlhits1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                   for z = 1:length(h)
                       figure(6)
                       bar(h(z),meanlhits1(z),0.5,'FaceColor',color{z});
                       %         plot(h(z),nanmean(lhits{z})+rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                       %         plot(h(z),nanmean(lhits{z})-rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                   end
                   for z=1:length(h2)
                       figure(6)
                       bar(h2(z),meanlhits2(z),0.5,'FaceColor',color{z});
                       %         plot(h2(z),nanmean(lhits{z})+rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                       %         plot(h2(z),nanmean(lhits{z})-rlqr{z},'o','MarkerFaceColor',[0.5 0 0.5]);
                   end
                   ylim([-0.25 0.25]);
                   title('Slow Leg Errors')
                   ylabel('Error (m)');
                                      
                   %save rhits and lhits
                   save('Results','rhits','lhits');
                   
               end
            end
        end
        
        function []=editTriallist(this)
            global t
            global ID
            ID = this.subjectcode;

            if isempty(this.triallist)%if triallist is empty, start from scratch
                [filenames,~] = uigetfiles('*.*','Select filenames');
            
                if iscell(filenames)
                    f = figure;
                    data = cell(length(filenames),4);
                    data(:,1)=filenames;
                    
                    for z=1:length(filenames)%autodetect if a trial was a train for evaluation
                        tname = filenames{z};
                        if strcmp(tname(end-5:end-4),'V3')
                            data{z,3} = 'train';
                        else
                            data{z,3} = 'eval';
                        end
                    end
                    
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data = cell(1,4);
                    data(1,1) = filenames;
                    if strcmp(filenames(end-5:end-4),'V3')
                        data(1,3) = 'train';
                    else
                        data(1,3) = 'eval';
                    end
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                end
                
            else %if triallist is already populated, just edit what is already there
                [filenames,~] = uigetfiles('*.*','Select filenames');
                if iscell(filenames)
                    f = figure;
                    data = cell(length(filenames),4);
                    data(:,1)=filenames;
                    data(:,2:4) = this.triallist(:,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                else
                    f = figure;
                    data = cell(1,4);
                    data(1,1) = filenames;
                    data(1,2:4) = this.triallist(1,2:4);
                    colnames = {'Filename','#','type','category'};
                    columnformat = {'char','numeric',{'train','eval'},{'training','baseline','adaptation','washout'}};
                    t=uitable(f,'Position',[10,10,375,375],'Data',data,'ColumnName',colnames,'ColumnFormat',columnformat,'ColumnEditable',[true true true true]);
                    set(t,'celleditcallback','global ID;global t;temp = get(t,''Data'');eval([ID ''.triallist = temp;'']);');
                    set(t,'DeleteFcn','global ID;eval([ID ''.saveit()'']);');
                end
                
            end
        end
        
        function []=saveit(this)%save instance as the "subjectcode_SLBF"
            
            if isempty(this.subjectcode)
                cprintf('err','WARNING: save failed, no valid ID present');
            else
                savename = [this.subjectcode '_SLBF_day' num2str(this.day) '.mat'];
                eval([this.subjectcode '=this;']);
                save(savename,this.subjectcode);
            end
        end
        
        function []=comparedays(this)
            %make bar plots of day1 and day2 means to compare performances
            %no inputs required, data is located from a uitable
            %
            %creates figures of bar plots for fast and slow legs, day 1 and
            %day 2
            
            %use a uitable to assign the locations of each Results.mat
            %file, should be 4 of them, 2 per day

            [file1,path1] = uigetfile('*.*','Select Day 1 File');
            [file2,path2] = uigetfile('*.*','Select Day 2 File');
            
            %deal with day 1
            load([path1,'Results.mat']);
            tlist1 = this.triallist;% must be day1 instance loaded as this
            if strcmp(this.dominantleg,'R')
                fast1 = rhits;
                slow1 = lhits;
            else
                fast1 = lhits;
                slow1 = rhits;
            end
            
            clear rhits lhits
            
            load([path2,'Results.mat']);
            load([path2,file2]);%make sure this is the day2 instance otherwise will probably crash
            file3 = [file2(1:6) file2(end-8:end-4)];
            eval(['tlist2 = ' file3 '.triallist;']);
            if strcmp(this.dominantleg,'R')
                fast2 = rhits;
                slow2 = lhits;
            else
                fast2 = lhits;
                slow2 = rhits;
            end
            clear rhits lhits
            
            if length(tlist1)==length(tlist2)
                train = find(strcmp(tlist1(:,4),'training'));%logicals of where training trials are
                base = find(strcmp(tlist1(:,4),'baseline'));
                adapt = find(strcmp(tlist1(:,4),'adaptation'));
                wash = find(strcmp(tlist1(:,4),'washout'));
                
                colors1 = cell(length(tlist1),1);
                colors2 = cell(length(tlist1),1);
                for z=1:length(tlist1)
                   if strcmp('train',tlist1(z,3))
                       colors1{z}=[0 102/256 204/256];
                       colors2{z}=[0 1 1];
                   else
                       colors1{z}=[1 0 0];
                       colors2{z}=[1 128/256 0];
                   end
                end
                
                for z=1:length(fast1)
                    temp1 = fast1{z};
                    temp2 = fast2{z};
                    temp1(abs(temp1) > 0.1) = [];
                    temp2(abs(temp2) > 0.1) = [];
                    meanfast1(z) = mean(temp1);
                    meanfast2(z) = mean(temp2);
                    stdfast1(z) = std(temp1);
                    stdfast2(z) = std(temp2);
                end
                
                for z=1:length(slow1)
                    temp1 = slow1{z};
                    temp2 = slow2{z};
                    temp1(abs(temp1) > 0.1) = [];
                    temp2(abs(temp2) > 0.1) = [];
                    meanslow1(z) = mean(temp1);
                    meanslow2(z) = mean(temp2);
                    stdslow1(z) = std(temp1);
                    stdslow2(z) = std(temp2);
                end
                
                hand = zeros(4,1);
                %fast leg
                figure(7)
                hold on
                fill([0 2*length(train)+0.5 2*length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                fill([2*length(train)+0.5+2*length(base) 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+0.5+2*length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                h = 1:2:2*length(meanfast1);
                h2 = 1.5:2:2*length(meanfast2);
                errorbar(h,meanfast1,stdfast1,'k','LineWidth',1.5);
                errorbar(h2,meanfast2,stdfast2,'k','LineWidth',1.5);
                plot([0 2*length(meanfast1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                plot([0 2*length(meanfast1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                for z = 1:2:length(h)%trainings
                    figure(7)
                    hand(1) = bar(h(z),meanfast1(z),0.5,'FaceColor',colors1{z});
                end
                for z = 2:2:length(h)%evaluations
                    figure(7)
                    hand(2) = bar(h(z),meanfast1(z),0.5,'FaceColor',colors1{z});
                end
                for z=1:2:length(h2)
                    figure(7)
                    hand(3) = bar(h2(z),meanfast2(z),0.5,'FaceColor',colors2{z});
                end
                for z=2:2:length(h2)
                    figure(7)
                    hand(4) = bar(h2(z),meanfast2(z),0.5,'FaceColor',colors2{z});
                end
                ylim([-0.25 0.25]);
                title([this.subjectcode ' Fast Leg Day 1 vs. Day 2 Errors']);
                ylabel('Error (m)');
                legend(hand,'train D1','eval D1','train D2','eval D2')
%                 keyboard

                figure(8)
                hold on
                fill([0 2*length(train)+0.5 2*length(train)+0.5 0],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                fill([2*length(train)+0.5+2*length(base) 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+2*length(base)+2*length(adapt)+0.5 2*length(train)+0.5+2*length(base)],[0.255 0.255 -0.255 -0.255],[230 230 230]./256);
                h = 1:2:2*length(meanslow1);
                h2 = 1.5:2:2*length(meanslow2);
                errorbar(h,meanslow1,stdslow1,'k','LineWidth',1.5);
                errorbar(h2,meanslow2,stdslow2,'k','LineWidth',1.5);
                plot([0 2*length(meanslow1)+1],[0.0375 0.0375],'--k','LineWidth',2);%tolerance lines
                plot([0 2*length(meanslow1)+1],[-0.0375 -0.0375],'--k','LineWidth',2);
                for z = 1:2:length(h)%trainings
                    figure(8)
                    hand(1) = bar(h(z),meanslow1(z),0.5,'FaceColor',colors1{z});
                end
                for z = 2:2:length(h)%evaluations
                    figure(8)
                    hand(2) = bar(h(z),meanslow1(z),0.5,'FaceColor',colors1{z});
                end
                for z=1:2:length(h2)
                    figure(8)
                    hand(3) = bar(h2(z),meanslow2(z),0.5,'FaceColor',colors2{z});
                end
                for z=2:2:length(h2)
                    figure(8)
                    hand(4) = bar(h2(z),meanslow2(z),0.5,'FaceColor',colors2{z});
                end
                ylim([-0.25 0.25]);
                title([this.subjectcode ' Slow Leg Day 1 vs. Day 2 Errors']);
                ylabel('Error (m)');
                legend(hand,'train D1','eval D1','train D2','eval D2')

                            end
            
%             keyboard
            
        end
            
    end
    
end

