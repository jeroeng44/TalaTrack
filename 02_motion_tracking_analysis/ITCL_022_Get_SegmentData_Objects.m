function [Objects_CT, Fiducials_CT] = ITCL_022_Get_SegmentData_Objects(CT_InputDIR, ObjectNames, MarkerNames)
    
    Objects_CT = Get_CTObjects(CT_InputDIR, ObjectNames);
    
    Fiducials_CT = Get_CTMarkerGeometry(CT_InputDIR, MarkerNames);
    
    % Vectors_CT = Get_CTVectors(CT_InputDIR, VectorNames); % TJ: For 3D Vector versions we pull vectors rather from the csv
end


function [Objects_CTCoord] = Get_CTObjects(ObjectDIR, ObjectList)
    Objects_CTCoord = cell(1, length(ObjectList));
        
        for i = 1:length(ObjectList)
            name = ObjectList{i};
            ObjectPath = sprintf('Segmentation_%s.stl',name);
            FilePath = [ObjectDIR filesep ObjectPath];
            try
                Objects_CTCoord{i} = Read_3DSlicer_to_Points(FilePath); % dimension (3,N)
            catch
                Objects_CTCoord{i} = zeros(3,1);
            end
        end
end

function [Fiducials_CTCoord] = Get_CTMarkerGeometry(MarkerDIR, MarkerList)
    NumberMarkers = size(MarkerList,2);
    Fiducials_CTCoord = cell(1,NumberMarkers); %for fiducials per marker
    for i = 1:NumberMarkers
        Marker = MarkerList(i);
        % FilePath_CTCoord_Markers = strcat(MarkerDIR,'F_',string(Marker),'.json'); % Needs to be .json File
        ObjectPath = sprintf('F_%d.json',Marker);
        FilePath_CTCoord_Markers = [MarkerDIR filesep ObjectPath];
        % FilePath_CTCoord_Markers = strcat(MarkerDIR,'MotionMarker_',string(Marker),'.json'); % Needs to be .json File
        try
            Fiducials_CTCoord{i} = Read_3DSlicer_to_Points(FilePath_CTCoord_Markers); % Coordinates of 4 points on a Marker [F0, F1, F2, F3]
        catch
            Fiducials_CTCoord{i} = zeros(3,1);
            fprintf('Could not load %s\n', FilePath_CTCoord_Markers)
        end
    end
end



function [Vectors_CTCoord] = Get_CTVectors(VectorDIR, VectorList)
    NumberVectors = size(VectorList,2);
    Vectors_CTCoord = cell(1,NumberVectors); %for fiducials per marker
    for i = 1:NumberVectors
        VectorName = VectorList{i};
        % FilePath_CTCoord_Markers = strcat(MarkerDIR,'F_',string(Marker),'.json'); % Needs to be .json File
        ObjectPath = sprintf('%s.json',VectorName);
        FilePath_CTCoord_Vector = [VectorDIR filesep ObjectPath];
        % FilePath_CTCoord_Markers = strcat(MarkerDIR,'MotionMarker_',string(Marker),'.json'); % Needs to be .json File
        try
            Curr_Points = Read_3DSlicer_to_Points(FilePath_CTCoord_Vector); % Coordinates of 2 points defining the relevant vector
            
            Vectors_CTCoord{i} = Curr_Points(:,1) - Curr_Points(:,2); % Coordinates of 4 points on a Marker [F0, F1, F2, F3]
        catch
            Vectors_CTCoord{i} = zeros(3,1);
            fprintf('Could not load %s\n', FilePath_CTCoord_Vector)
        end
    end
end