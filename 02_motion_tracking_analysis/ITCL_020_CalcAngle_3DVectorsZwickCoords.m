function [All_angles, AngleNames, All_Times] = ITCL_020_CalcAngle_3DVectorsZwickCoords(MainDIR, CT_InputDIR, Motion_InputDIR, Segmentation_OutputDIR, Plots_OutputDIR, SimulationYesNo)
    
    MainDIR = MakeCorrectDIR(MainDIR);
    Motion_InputDIR = MakeCorrectDIR(Motion_InputDIR);
    CT_InputDIR = MakeCorrectDIR(CT_InputDIR);
    Segmentation_OutputDIR = MakeCorrectDIR(Segmentation_OutputDIR);
    
    %% Initialization
    RefMarker_ID =1; 
    ObjectNames = {'RefMarker', 'Tibia', 'Talus', 'Calc', 'Meta', 'Navi'};
    MarkerNames = [299, 301, 302, 311, 314, 320]; %need to ensure, that these marker names match the bone names
    Number_Objects = length(ObjectNames);
        
    AngleNames = {'Lateral Mearys angle', 'Tibia-Calcaneal angle', 'Talus-Calcaneus angle', 'AP Mearys angle', 'Talonavicular coverage angle'};
    
    %eventuell anpassen angleVectors check experiment 02 wegen vorzeichen!
    
    %AngleVectors = {'Meta_MainAxis', 'Talus_MainAxis', ...
     %   'Calc_VertAxis' ,'Tibia_MainAxis', ...
      %  'Calc_VertAxis' ,'Talus_VertAxis',...
       % 'Talus_MainAxis', 'Meta_MainAxis', ...
        %'Navi_MainAxis', 'Talus_MainAxis'};

    AngleVectors = {'Talus_MainAxis', 'Meta_MainAxis', ...
        'Tibia_MainAxis' ,'Calc_VertAxis', ...
        'Talus_VertAxis', 'Calc_VertAxis', ...
        'Talus_MainAxis', 'Meta_MainAxis', ...
        'Talus_MainAxis', 'Navi_MainAxis'};

    AnglePlanes = {'Sagittal', 'Coronal', 'Coronal', 'Axial', 'Axial'};
    Number_Angles = length(AngleNames);
    
    %% Calibrate Zwick Coordinates
    
    [R_RefMarker_to_Zwick, T_RefMarker_to_Zwick] = ITCL_021_Get_ZwickCoordConfig(MainDIR);

    %% Get MotionMarker Data for all timestamps
    % Retrieve all motion marker data once, to be used for each marker
    % [All_Geometry, AllMarker_Rotation, AllMarker_Translation, ~, Number_Timestamps] = ...
    %     GetFolder_MotionMarker_Data(Marker_InputDIR, MarkerNames, false);
    [All_Geometry, AllMarker_Rotation, AllMarker_Translation, ~, All_Times, Number_Timestamps] = ...
        GetFolder_MotionMarker_Data_withTime(Motion_InputDIR, MarkerNames, false);
    
    %comment out if you want all
    %Number_Timestamps = 10 ;
    All_Times = All_Times(1:Number_Timestamps);

    %% Get Segmentation data and Vectors
    % Function to extract the segmentations in the CT folder
    % Points_CT{i} is the full object, Fiducials_CT{i} is the corresponding Marker Fiducials in CT Coord
    [Points_CT, Fiducials_CT] = ITCL_022_Get_SegmentData_Objects(CT_InputDIR, ObjectNames, MarkerNames); 
    
    [VecP_CT, VecV_CT, VectorNames, MarkerNames_Vectors, Number_Vectors] = ITCL_022_Get_SegmentData_3DVectors(CT_InputDIR); % need to program this better

    %% Initalize storage for timestamps - note: no need to store cam data points, can be removed if needed
    % Initialize a structure to store results by timestamp and object
    R_CT_to_Marker = cell(1,Number_Objects);
    T_CT_to_Marker = cell(1,Number_Objects);
    % Intialize storage for Object points in different Coordinate Systems
    Points_Marker = cell(1,Number_Objects); %Object points in Marker system, same structure as Points_CT
    Points_Cam = cell(Number_Timestamps,Number_Objects); %Object points in camera system at timestamp; 3xN array for each timestamp and object
    Points_RefOutput = cell(Number_Timestamps,Number_Objects); %Object Points in Reference CT system at timestamp; 3xN array for each timestamp and object - need to choose one reference marker
    
    % Intialize storage for vectors in different Coordinate Systems
    VecP_Marker = cell(1,Number_Vectors);
    VecV_Marker = cell(1,Number_Vectors);
    VecP_Cam  = cell(Number_Timestamps,Number_Vectors);
    VecV_Cam = cell(Number_Timestamps,Number_Vectors);
    VecP_RefOutput = cell(Number_Timestamps,Number_Vectors);
    VecV_RefOutput = cell(Number_Timestamps,Number_Vectors);

    %% Loop through each marker ID in order to get CT to Marker transformations
    for MarkerID = 2:Number_Objects % only loop from 2 onwards, as we are not intersted in the reference marker
        %% Transformation to intrinsic marker system
        % Extract fiducials for the current marker ID
        Points_CT_Curr = Points_CT{MarkerID};
        
       
        % Optimize position of markers on CT to have correct geometry -> less uncertainties when using SVD
        %Fiducials_CT_Curr = Fiducials_CT{MarkerID}; % Fiducials in CT system
        Fiducials_CT_Curr = Optimize_Fiducials(Fiducials_CT{MarkerID}, MarkerNames(MarkerID),false); 
        
        % Extract marker fiducials in intrinsic marker system
        Fiducials_Marker_Curr = Get_Fiducial_MarkerCoord(MarkerNames(MarkerID)); 
        
        % Compute abd store coordinate transformation using SVD for current marker ID
        [R_CT_to_Marker_Curr, T_CT_to_Marker_Curr] = Get_CoordinateTransformation_SVD(Fiducials_CT_Curr, Fiducials_Marker_Curr);
        R_CT_to_Marker{MarkerID} = R_CT_to_Marker_Curr;
        T_CT_to_Marker{MarkerID} = T_CT_to_Marker_Curr;

        % Transform objects from CT to marker coordinate system
        Points_Marker{MarkerID} = Apply_CoordinateTransformation_Points(Points_CT_Curr, R_CT_to_Marker_Curr, T_CT_to_Marker_Curr, 'normal');

        % Transform vectors from CT to intrinsic Marker System
        for vectorID = findIndices(MarkerNames_Vectors, MarkerNames(MarkerID))
            VecP_CT_Curr = VecP_CT{vectorID};
            VecP_Marker{vectorID} = Apply_CoordinateTransformation_Points(VecP_CT_Curr, R_CT_to_Marker_Curr, T_CT_to_Marker_Curr, 'normal');
            VecV_Marker{vectorID} = R_CT_to_Marker_Curr * VecV_CT{vectorID};
        end
    end
    
    %% Prepare Savenames
    ref_timestamp = 1; % we want the first frame to be the reference frame for our output - this is only relevant for the 
    dataDir_RefOutput = Segmentation_OutputDIR;
    createDirIfNotExist(dataDir_RefOutput);

    %% Apply motion for each timestamp and store results in a structured format
    for timestamp = 1:Number_Timestamps
        %Prepare transformation to Ref CT system
        R_RefMarker_to_Cam = reshape(AllMarker_Rotation(:,:,ref_timestamp,RefMarker_ID), [3, 3]);
        T_RefMarker_to_Cam = reshape(AllMarker_Translation(:,ref_timestamp,RefMarker_ID), [3, 1]);
        
        for MarkerID = 2:Number_Objects % only loop from 2 onwards, as we are not intersted in the reference marker
            R_Marker_to_Cam_Curr = reshape(AllMarker_Rotation(:,:,timestamp,MarkerID), [3, 3]);
            T_Marker_to_Cam_Curr = reshape(AllMarker_Translation(:,timestamp,MarkerID), [3, 1]);
            
            %% Move point clouds
            if SimulationYesNo
                Points_Marker_Curr = Points_Marker{MarkerID};
    
                % Transform points from Marker to Camera system
                Points_Cam_Curr = Apply_CoordinateTransformation_Points(Points_Marker_Curr, R_Marker_to_Cam_Curr, T_Marker_to_Cam_Curr, 'normal');
                Points_Cam{timestamp,MarkerID} = Points_Cam_Curr;
    
                % Transform to reference system
                Points_RefMarker_Curr = Apply_CoordinateTransformation_Points(Points_Cam_Curr, R_RefMarker_to_Cam, T_RefMarker_to_Cam, 'inv');
                Points_RefOutput_Curr = Apply_CoordinateTransformation_Points(Points_RefMarker_Curr, R_RefMarker_to_Zwick, T_RefMarker_to_Zwick, 'normal');
                Points_RefOutput{timestamp,MarkerID} = Points_RefOutput_Curr;
    
                % Save the variables
                Label = sprintf('%s_%04d.mat', ObjectNames{MarkerID}, timestamp);
                SaveName_RefOutput = fullfile(dataDir_RefOutput, Label); % Construct full file path
                save(SaveName_RefOutput, 'Points_RefOutput_Curr');

                %DEBUG here with points_Cam_Curr
                % DEBUG: Save Points_Cam_Curr for inspection
                DebugOutputDir_Cam = fullfile(MainDIR, 'DebugPointsCam');
                if ~exist(DebugOutputDir_Cam, 'dir')
                    mkdir(DebugOutputDir_Cam); % Create the directory if it doesn't exist
                end
                
                % Construct a save label for Points_Cam_Curr
                DebugLabel_Cam = sprintf('%s_%04d.mat', ObjectNames{MarkerID}, timestamp);
                DebugSaveName_Cam = fullfile(DebugOutputDir_Cam, DebugLabel_Cam);
                
                % Save Points_Cam_Curr in the debug folder
                save(DebugSaveName_Cam, 'Points_Cam_Curr');
            end
            
            
            %% Move Vectors
            % Transform vectors from CT to intrinsic Marker System
            for vectorID = findIndices(MarkerNames_Vectors, MarkerNames(MarkerID))
                VecP_Marker_Curr = VecP_Marker{vectorID};
    
                % Transform vector endpoints from Marker to Camera system
                VecP_Cam_Curr = Apply_CoordinateTransformation_Points(VecP_Marker_Curr, R_Marker_to_Cam_Curr, T_Marker_to_Cam_Curr, 'normal');
                VecP_Cam{timestamp,vectorID} = VecP_Cam_Curr;
    
                % Transform vector endpoints to reference system
                VecP_RefMarker_Curr = Apply_CoordinateTransformation_Points(VecP_Cam_Curr, R_RefMarker_to_Cam, T_RefMarker_to_Cam, 'inv');
                VecP_RefOutput_Curr = Apply_CoordinateTransformation_Points(VecP_RefMarker_Curr, R_RefMarker_to_Zwick, T_RefMarker_to_Zwick, 'normal');
                VecP_RefOutput{timestamp,vectorID} = VecP_RefOutput_Curr;
                
                % Transform Vector to camera system
                VecV_Cam{timestamp, vectorID} = R_Marker_to_Cam_Curr * VecV_Marker{vectorID};
                % Transform Vector to Ref CT system - should not have an impact on the angle calculation
                VecV_RefOutput{timestamp, vectorID} = R_RefMarker_to_Zwick * R_RefMarker_to_Cam' * VecV_Cam{timestamp, vectorID};
                
                

                test_vec = VecV_RefOutput{timestamp, vectorID} - VecP_RefOutput{timestamp,vectorID}(:,1) + VecP_RefOutput{timestamp,vectorID}(:,2);
                % 
                %p1 = VecP_RefOutput{timestamp,vectorID}(:,1)
                %p2 = VecP_RefOutput{timestamp,vectorID}(:,2)
                %v_p = p1 - p2;
                %v = VecV_RefOutput{timestamp,vectorID}
                %disp(v - v_p)
                
                if norm(test_vec)>10^-1
                    error('Miscalculation')
                end


                % Save the variables
                Label = sprintf('%s_%04d.mat', VectorNames{vectorID}, timestamp);
                SaveName_RefOutput = fullfile(dataDir_RefOutput, Label); % Construct full file path

                FullLine_VecP_RefOutput_Curr = MakeFullLine(VecP_RefOutput_Curr);

                save(SaveName_RefOutput, 'FullLine_VecP_RefOutput_Curr');
            end
        end
    end
    

    %% Calculate the final angles
    
    All_angles = zeros(Number_Timestamps, Number_Angles);
    for angle_id = 1:Number_Angles
        v1_name = AngleVectors{2*angle_id - 1};
        v1_id = find(strcmp(VectorNames, v1_name));

        v2_name = AngleVectors{2*angle_id};
        v2_id = find(strcmp(VectorNames, v2_name));
        
        currAngle = AngleNames{angle_id};
        currPlane = AnglePlanes{angle_id};
        
        fprintf('%s via %s (%d) and %s (%d)\n', currAngle, v1_name, v1_id, v2_name, v2_id)
        fprintf('%s on CT: %f °\n', currAngle, round(Calculate_signed_Angle_Plane(VecV_CT{v1_id}, VecV_CT{v2_id}, currPlane),1))
        % pause
        for timestamp = 1:Number_Timestamps
            vector_1 = VecV_RefOutput{timestamp, v1_id};
            vector_2 = VecV_RefOutput{timestamp, v2_id};
            % See powerpoint disuccion regarding angle calculation
            All_angles(timestamp,angle_id) = Calculate_signed_Angle_Plane(vector_1, vector_2, currPlane);
            % % All_angles(timestamp,angle_id) = Calculate_3D_Angle(vector_1, vector_2);
 

            AngleDiff = abs(Calculate_3D_Angle(vector_1, vector_2) - Calculate_3D_Angle(VecV_Cam{timestamp, v1_id}, VecV_Cam{timestamp, v2_id}));
            if AngleDiff > 10^-5
                error('Issue with angle calc')
            end
        end
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


function [indices] = findIndices(List, targetValue)
    indices = find(List == targetValue);
end


function [alpha] = Calculate_3D_Angle(v1, v2)
    if norm(v1)*norm(v2) ~= 0
        alpha_rad = acos(dot(v1, v2) / (norm(v1) * norm(v2)));
    elseif norm(v1)*norm(v2) == 0
        alpha_rad = 0;
    end
    alpha = rad2deg(alpha_rad);
end


function [alpha] = Calculate_signed_Angle_Plane(v1, v2, plane)
    % Calculate_signed_Angle_Plane calculates the signed angle between two vectors in a specified plane
    %
    % Inputs:
    %   v1 - the first vector (3D)
    %   v2 - the second vector (3D)
    %   plane - the plane in which to project ('axial', 'coronal', 'sagittal')
    %
    % Output:
    %   alpha - signed angle between the projected vectors in degrees

    % Define projection vectors and sign projection vectors based on specified plane
    switch lower(plane)
        case 'axial'
            project_vector = [1, 1, 0]';
            sign_proj = [0, 0, 1]'; % z-axis for axial
        case 'coronal'
            project_vector = [1, 0, 1]'; 
            sign_proj = [0, 1, 0]'; % y-axis for coronal
        case 'sagittal'
            project_vector = [0, 1, 1]'; % check
            sign_proj = [1, 0, 0]'; % y-axis for sagittal
        otherwise
            error('Irregular angle plane: %s\n', plane)
    end

    % Project v1 and v2 onto the specified plane
    v1 = project_vector .* v1;
    v2 = project_vector .* v2;

    % Calculate the unsigned angle in radians
    
    if norm(v1)*norm(v2) ~= 0
        alpha_rad = acos(dot(v1, v2) / (norm(v1) * norm(v2)));
    elseif norm(v1)*norm(v2) == 0
        alpha_rad = 0;
    end

    % Calculate the cross product to determine the angle's sign
    cross_prod = cross(v1, v2);
    sign_component = dot(cross_prod, sign_proj);

    % Convert the angle to degrees and apply the sign
    alpha = sign(sign_component) * rad2deg(alpha_rad);
end




function [Line] = MakeFullLine(Points)
    dist = 0.5;
    % Extract the start and end points
    p1 = Points(:,1); % Starting point
    p2 = Points(:,2); % Ending point

    % Calculate the total distance between p1 and p2
    totalDistance = norm(p2 - p1);
    
    % Calculate the number of points based on the desired distance
    numPoints = round(totalDistance / dist);

    % Initialize the line array
    Line = zeros(3, numPoints);

    % Generate the points along the line with the specified distance
    for i = 1:numPoints
        t = (i - 1) * dist / totalDistance;  % Linear interpolation parameter (from 0 to 1)
        Line(:, i) = (1 - t) * p1 + t * p2;  % Linear interpolation formula
    end
end