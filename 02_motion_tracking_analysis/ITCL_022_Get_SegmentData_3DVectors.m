function [Endpoints, Vectors, VectorNames, MarkerNames, No_Vectors] = ITCL_022_Get_SegmentData_3DVectors(Folder)
    VectorNames = {'Talus_MainAxis', 'Meta_MainAxis', 'Tibia_MainAxis', 'Calc_VertAxis', 'Talus_VertAxis', 'Navi_MainAxis'};
    MarkerNames = [302, 314, 301, 311, 302, 320];
    No_Vectors = length(VectorNames);
    [Data_Points, Data_Vectors] = Get_SegmentationVectors(Folder, VectorNames, MarkerNames);
    
    Endpoints = cell(1,No_Vectors);
    Vectors = cell(1,No_Vectors);

    for i = 1:No_Vectors
        CurrVec = VectorNames{i};
        Endpoints{1,i} = Data_Points.(CurrVec);
        Vectors{1,i} = Data_Vectors.(CurrVec);
    end
end


function [Data_Points, Data_Vectors] = Get_SegmentationVectors(Folder, VectorNames, MarkerNames)
    % Prepare Outputs
    Data_Points = struct();
    Data_Vectors = struct();
    
    % Read csv tables
    csv_Name = 'ITCL_Vectors.csv';
    FileName = fullfile(Folder, csv_Name);
    table = readtable(FileName);
    No_entries = size(table.x1,1);
    
    % Assign csv data to data storage
    for i = 1: No_entries
        vecName = table.VetorName(i);
        currName = vecName{1};
        currMarker = table.MarkerName(i);
        if not(strcmp(currName, VectorNames{i}))
            error('Wrong Vectors in csv');
        elseif currMarker ~=MarkerNames(i)
            error('Wrong marker in csv');
        end
        
        curr_Points = zeros(3,2);
        curr_Vec = zeros(3,1);
        p1 = [table.x1(i), table.y1(i), table.z1(i)];
        curr_Points(:,1) = p1;
        p2 = [table.x2(i), table.y2(i), table.z2(i)];
        curr_Points(:,2) = p2;
        v = [table.v_x(i), table.v_y(i), table.v_z(i)];
        curr_Vec(:,1) = v;
        Data_Points.(currName) = curr_Points;
        Data_Vectors.(currName) = curr_Vec;
    end
end