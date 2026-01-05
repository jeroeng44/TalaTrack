function ITCL_010_SingleExp_3DVectorsZwickCoords(MainDIR, ITCLorMedialFirst)
    %% Prepare required input
    % make sure to adapt if the series change
    % % Main DIR for testing
    
    % Main DIR ITCL Experiment 1
    MainDIR = 'P:\jeroeng\07_Zivi\02_Data\02_ITCL\02 Measurement Series\01_ITCL_Exp_01';
    ITCLorMedialFirst = 'Medial';

    %% Get relevant directories
    [CT_InputDIR, Motion_InputDIRs, Segmentation_OutputDIRs, Plots_OutputDIRs, Consolidated_OutputDIR, scenario_labels] = ...
        ITCL_011_Get_RelevantDIRs(MainDIR, ITCLorMedialFirst); %each should give a list of strings, where they denote the directories for the different
    
    %% Set to true or false for saving of simulation
    SimulationYesNo = false; % !!Long computation times!! this can be set to true, if we want to save the segmentations for each timestep,    
    
    %% Calculate the angle for the scenarios
    % Initialization
    No_Scenarios = size(scenario_labels,2);
    Data_Angle = struct(); % here we store all the angle data, we also need to store the timestamps somehow...
    Data_Time = struct(); % we also need to store the time for hte different series...
    Data_AngleNames = struct(); % tbd if this is needed for quality assurance (I beeive not, as angle names are hardcoded...)

    %No_Scenarios = 2;
    % Loop through the scenarios and gather the respective data
    
    % Here we could parallelize
    
    for i = 1:No_Scenarios        
        % Perform Measurement Analysis
        Marker_InputDIR = Motion_InputDIRs{i};
        Segmentation_OutputDIR = Segmentation_OutputDIRs{i};
        Plots_OutputDIR = Plots_OutputDIRs{i};
        [All_angles, AngleNames, All_Times] = ... % we actually only want All_angles and accordingly their names
            ITCL_020_CalcAngle_3DVectorsZwickCoords(MainDIR, CT_InputDIR, Marker_InputDIR, ...
            Segmentation_OutputDIR, Plots_OutputDIR, SimulationYesNo);
        
        % Store Data in Struct
        currScenario = scenario_labels{i};
        Data_Angle.(currScenario) = All_angles;
        Data_Time.(currScenario) = All_Times;
        Data_AngleNames.(currScenario) = AngleNames; % TBD if this needed for qualty assurance (compare across scenarios)
        close all; % we need this, as otherwhise it becomes a mess witht he figure IDs
    end
    
    %% Save Calculation Data
    MakeCorrectDIR(Consolidated_OutputDIR)
    % Data_Angle
    Label = 'Data_Angle.mat'
    SaveName = fullfile(Consolidated_OutputDIR, Label); % Construct full file path
    save(SaveName, 'Data_Angle');
    % Data_Time
    Label = 'Data_Time.mat'
    SaveName = fullfile(Consolidated_OutputDIR, Label); % Construct full file path
    save(SaveName, 'Data_Time');
    % Data_AngleNames
    Label = 'Data_AngleNames.mat'
    SaveName = fullfile(Consolidated_OutputDIR, Label); % Construct full file path
    save(SaveName, 'Data_AngleNames');
    
    %% Make Plots
    No_Angles = 5; % potentially also pull from somewhere
    
    % find ymin and ymax
    ally_min = zeros(1,No_Angles);
    ally_max = zeros(1,No_Angles);
    
    for angle_id = 1: No_Angles
        ang_min = 1000;
        ang_max = -1000;
        for i = 1:No_Scenarios
            currScenario = scenario_labels{i};
            curr_Data_Angle = Data_Angle.(currScenario);
            angleData = curr_Data_Angle(:,angle_id);
            curr_min = min(angleData);
            curr_max = max(angleData);
            if curr_min < ang_min
                ang_min = curr_min;
            end
            if curr_max > ang_max
                ang_max = curr_max;
            end
        end
        ally_min(1,angle_id) = round(ang_min-0.65);
        ally_max(1,angle_id) = round(ang_max+0.65);
    end


    for angle_id = 1: No_Angles
        currAngle = AngleNames{angle_id};
        fig = figure(angle_id);
        % Set the figure to full screen
        set(fig, 'Units', 'normalized', 'OuterPosition', [0 0 1 1]);

        for i = 1:No_Scenarios
            subplot(3, 3, i)
            currScenario = scenario_labels{i};
            curr_Data_Angle = Data_Angle.(currScenario);
            curr_Data_Time = Data_Time.(currScenario);
            plot(curr_Data_Time, curr_Data_Angle(:,angle_id), '.--', 'LineWidth', 1.0, 'MarkerSize',10);
            xlabel('Time [sec]');
            ylabel(sprintf('%s [deg]',currAngle));
            title(currAngle);
            subtitle(strrep(currScenario, '_', ' '))
            ylim([ally_min(1,angle_id) ally_max(1,angle_id)]);
        end
                
        
        PlotName = strrep(currAngle, ' ', '_');
        
        % legend(scenario_labels);
        saveas(fig,[Consolidated_OutputDIR,PlotName,'.pdf']);
        saveas(fig,[Consolidated_OutputDIR,PlotName,'.png']);
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
