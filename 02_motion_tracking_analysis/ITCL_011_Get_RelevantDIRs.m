function [CT_InputDIR, Motion_InputDIRs, Segmentation_OutputDIRs, Plots_OutputDIRs, Consolidated_OutputDIR, Scenario_Names] = ...
        ITCL_011_Get_RelevantDIRs(MainDIR, ITCLorMedialFirst) %each should give a list of strings, where they denote the directories for the different

    Motion_InputDIRs = cell(1,3);
    Segmentation_OutputDIRs = cell(1,3);
    Plots_OutputDIRs = cell(1,3);

    CT_Sub_DIR = '/01_CT_Data/Segmentation/';
    
    Motion_Sub_DIR = '/02_MotionMarker_Data/';
    
    Output_Sub_DIR = '/03_Output/';
    Output_Seg_DIR = '02 SegmentationMotion';
    Ouptut_Plot_DIR = '/01 Plot Output/';

    Consolidated_Sub_DIR = '/03_Output/08_Consolidated/';
    
    switch ITCLorMedialFirst
        case 'Medial'
            Series_Names = {'/01_Healthy/', '/02_Flatfood_MedialCut/', '/03_Flatfood_BothCut/',...
                '/04_Reko_Medial/', '/05_Reko_Both/', '/06_Reko_ITCL/', '/07_Flatfood_BothCut/', '/08_Flatfood_BothCut/'};           
            
            Scenario_Names = {'M01_Healthy', 'M02_Flatfood_MedialCut', 'M03_Flatfood_BothCut',...
                'M04_Reko_Medial', 'M05_Reko_Both', 'M06_Reko_ITCL', 'M07_Flatfood_BothCut', 'M08_Flatfood_BothCut'};
        case 'ITCL'
            Series_Names = {'/01_Healthy/', '/02_Flatfood_ITCLCut/', '/03_Flatfood_BothCut/',...
                '/04_Reko_ITCL/', '/05_Reko_Both/', '/06_Reko_Medial/', '/07_Flatfood_BothCut/', '/08_Flatfood_BothCut/'};

            Scenario_Names = {'M01_Healthy', 'M02_Flatfood_ITCLCut', 'M03_Flatfood_BothCut',...
                'M04_Reko_ITCL', 'M05_Reko_Both', 'M06_Reko_Medial', 'M07_Flatfood_BothCut', 'M08_Flatfood_BothCut'};

        otherwise
            error('Invalid selction of ITCL or medial')
    end



    CT_InputDIR = [MainDIR CT_Sub_DIR];
    
    Consolidated_OutputDIR = [MainDIR Consolidated_Sub_DIR];

    for i = 1:size(Series_Names,2)
        Series_DIR = Series_Names{i};
        Motion_InputDIRs{i} = [MainDIR  Motion_Sub_DIR Series_DIR];
        Segmentation_OutputDIRs{i} = [MainDIR  Output_Sub_DIR Series_DIR Output_Seg_DIR];
        Plots_OutputDIRs{i} = [MainDIR  Output_Sub_DIR Series_DIR Ouptut_Plot_DIR];
    end
end


function [DirPath] = MakeCorrectDIR(PathString)
    if ~endsWith(PathString, filesep)
        DirPath = [PathString filesep];
    else
        DirPath = PathString;
    end

    if ~exist(DirPath)
        mkdir(DirPath)
    end
end
