function [R_RefMarker_to_Zwick, T_RefMarker_to_Zwick] = ITCL_021_Get_ZwickCoordConfig(MainDIR)
    %% Initalization
    DIR = [MainDIR '/00_ZwickCoordConfig/'];
    timestamp_name = 'singleCapture_0001.mat';
    filename = fullfile(DIR, timestamp_name);

    %% Pull data
    [Geometry_Refmarker, R_RefMarker_to_Cam, T_RefMarker_to_Cam] = Get_MotionMarker_Data(filename, 1);
    [Geometry_Zwick, R_Zwick_to_Cam, T_Zwick_to_Cam] = Get_MotionMarker_Data(filename, 2);


    %% Invert Zwick motion marker data
    [R_Cam_toZwick, T_Cam_to_Zwick] = Inverse_CoordinateTransformation(R_Zwick_to_Cam, T_Zwick_to_Cam);

    %% Connect coordinate transformation from RefMarker to Cam to Zwick
    [R_RefMarker_to_Zwick, T_RefMarker_to_Zwick] = Connect_CoordinateTransformation(R_RefMarker_to_Cam, T_RefMarker_to_Cam,...
        R_Cam_toZwick, T_Cam_to_Zwick);  

    %% Turn 90 deg around z- axis
    R_90 = zeros(3,3);
    R_90(1,2) = -1;
    R_90(2,1) = 1;
    R_90(3,3) = 1;
    R_RefMarker_to_Zwick = R_90 * R_RefMarker_to_Zwick;

    %% Apply 180° rotation around the X-axis to flip the Zwick coordinate system: to get rid of the negative directions of foot 6
    R_flip = [1  0  0;
              0 -1  0;
              0  0 -1];
    R_RefMarker_to_Zwick = R_flip * R_RefMarker_to_Zwick;
end



function [Geometry, RotMat, TransVec] = Get_MotionMarker_Data(FilePath, MarkerID)
    data = load(FilePath);
    markers = data.markers;
    marker = markers{1, MarkerID}; 
    RotMat = marker.rotation;
    TransVec = marker.translationMM;
    Uncertainty = marker.registrationErrorMM;
    Geometry = marker.geometryId;
end
