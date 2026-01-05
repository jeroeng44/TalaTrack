function [] = Experiment01_Measure_RawMarkerMovement(Marker_InputDIR, PlotDIR)
%% INPUT:
%  InputDIR_Name: (string) Directory path where the motion marker data is
%  stored. PlotDIR: (string) Directory path where the generated output
%  plots will be saved.
%% OUTPUT:
%  No direct output from this function. The function saves 3 plots in the
%  specified PlotDIR:
%    1. 'MarkerMotion_Translation': Residual translation of multiple
%    markers. 2. 'MarkerMotion_Rotation': Residual rotation of multiple
%    markers. 3. 'ReferenceMarker_Motion': Residual translation and
%    rotation of the reference marker (Marker 299).
%% DESCRIPTION:
%  The function first measures and plots the residual motion (translation
%  and rotation) of a reference marker (Marker 299). Then, it generates
%  subplots for the residual motion (translation and rotation) of
%  additional markers (302, 314, 301, and 311), linking their y-axes to
%  ensure consistent scaling between subplots. Finally, it saves the plots
%  in the specified output directory.


    % Ensure InputDIR_Name ends with the correct file separator
    if ~endsWith(Marker_InputDIR, filesep)
        Marker_InputDIR = [Marker_InputDIR filesep];
    end
    
    % Ensure PlotDIR ends with the correct file separator
    if ~endsWith(PlotDIR, filesep)
        PlotDIR = [PlotDIR filesep];
    end
    
    %% Initialization
    AllMarkers = [299, 301, 302, 311, 314, 320];
    AllObjects = {'RefMarker', 'Tibia', 'Talus', 'Calc', 'Meta', 'Navi'};
    
    %% Get MotionMarker Data
    [All_Geometry, AllMarker_Rotation, AllMarker_Translation, ~, Number_Timestamps] = GetFolder_MotionMarker_Data(Marker_InputDIR, AllMarkers, false);
    
    All_Geometry = All_Geometry/10 - 1000000;

    if ~isequal(All_Geometry, AllMarkers) && ~isequal(All_Geometry/10 - 1000000, AllMarkers)
        error('Measured and expected marers do not match')
    end

    %% Analyze and plot other marker residual motion    
    % Collect axis handles for linking
    ax_translation = [];
    ax_rotation = [];
    
    % Loop through each marker and generate subplots
    for MarkerID = 1:6
        disp(MarkerID)
        Marker_Rotation = reshape(AllMarker_Rotation(:,:,:,MarkerID), [3, 3, Number_Timestamps]);
        Marker_Translation = reshape(AllMarker_Translation(:,:,MarkerID), [3, Number_Timestamps]);   
        
        [ax_t, ax_r] = Prepare_MarkerMovement_SubPlots_ITCL(Marker_Rotation, Marker_Translation, AllMarkers(MarkerID), AllObjects{MarkerID}, MarkerID);
        ax_translation = [ax_translation, ax_t];  % Collect translation subplot axes
        ax_rotation = [ax_rotation, ax_r];        % Collect rotation subplot axes
    end
    
    % Link the y-axes of translation subplots in figure 1
    % linkaxes(ax_translation, 'y');  % Automatically adjust to have the same y-axis range
    % Optionally set specific limits for translation subplots
    % ylim(ax_translation, [0 0.1]);  % Example of manually setting limits

    % Link the y-axes of rotation subplots in figure 2
    % linkaxes(ax_rotation, 'y');     % Automatically adjust to have the same y-axis range
    % Optionally set specific limits for rotation subplots
    % ylim(ax_rotation, [-0.04 0.04]);  % Example of manually setting limits

    % Save the plots
    PlotName_1 = 'MarkerMotion_Translation';
    PlotName_2 = 'MarkerMotion_Rotation';
    
    figure(21);
    saveas(21,[PlotDIR,PlotName_1,'.pdf']);
    saveas(21,[PlotDIR,PlotName_1,'.png']);
    
    figure(22);
    saveas(22,[PlotDIR,PlotName_2,'.pdf']);
    saveas(22,[PlotDIR,PlotName_2,'.png']);
end


function [ax_t, ax_r] = Prepare_MarkerMovement_SubPlots_ITCL(Rotation, Translation, MotionMarker_Name, Object_Name, Plot_Pos)
%% INPUT:
%  InputDIR_Name: (string) Directory path where the motion marker data is stored.
%  MotionMarker_Name: (integer) The marker number for which the residual motion is to be measured.
%% OUTPUT:
%  ax_t: (axis handle) Handle to the translation subplot created for the specified marker.
%  ax_r: (axis handle) Handle to the rotation subplot created for the specified marker.
%% DESCRIPTION:
%  The function retrieves motion data for a given marker, calculates its residual motion (translation and rotation),
%  and creates two subplots: one for translation and one for rotation. It returns the axis handles for these subplots,
%  which are used for linking y-axes in the calling function.

    %% Initialization
    Number_Timestamps = size(Translation, 2);
    All_Timestamps = 1:Number_Timestamps;    

    %% Get Residual Motion
    [~, Residual_Euler, Residual_Translation, ~] = Calculate_Residual_Motion(Rotation, Translation, 1);
    
    %% Prepare Plots
    
    % Figure 21: Translation
    figure(21);
    disp(Plot_Pos)
    ax_t = subplot(2,3,Plot_Pos);  % Store the axis handle for translation subplot
    plot(All_Timestamps, sqrt(sum(Residual_Translation.^2)));
    title(sprintf('Marker %s',string(MotionMarker_Name)));
    subtitle(Object_Name)
    xlabel('Timestamp [N]');
    ylabel('\Delta position [mm]');
    
    % Figure 22: Rotation
    figure(22);
    ax_r = subplot(2,3,Plot_Pos);  % Store the axis handle for rotation subplot
    plot(All_Timestamps, Residual_Euler(2,:));
    title(sprintf('Marker %d',MotionMarker_Name));
    subtitle(Object_Name)
    % title(strcat('Marker',{' '},string(MotionMarker_Name),{' - '}, Object_Name));
    xlabel('Timestamp [N]');
    ylabel('\Delta y-Euler Angle [°]');
end