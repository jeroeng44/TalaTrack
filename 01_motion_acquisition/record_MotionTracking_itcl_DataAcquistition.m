function [] = record_MotionTracking_itcl_DataAcquistition()

clc
disp('Matlab Started.')

dataDIR = 'data'
% Check if the directory exists
if ~exist(dataDIR, 'dir')
    mkdir(dataDIR);  % Create the directory if it does not exist
    disp(['Directory created: ' dataDIR]);
else
    disp(['Directory already exists: ' dataDIR]);
end

%<<Pathes>>
addpath(genpath('GeometryFiles'));
addpath(genpath('MatlabWrapper2020b'));
addpath(genpath('STL Files'));
addpath(genpath('functions'));

%% <<Device Initialization>>
try
    s = FusionTrack;
    sn = s.devices;
    options = s.options(sn);
    options(4); % 1001
    s.setFloat32(sn, uint32(1001), single(0.31415));
end



if or(isempty(s),isempty(sn))
    clc
    display('Error: Could not initialize Camera!')
    pause(5)
%     exit
else
    display('Camera initialized!')
end

%% <<Load marker sets>>
% marker file paths
pathGeomFiles = 'GeometryFiles';
markerFiles = strings;
markerFiles(1) = 'geometry299.ini';
markerFiles(2) = 'geometry301.ini';
markerFiles(3) = 'geometry302.ini';
markerFiles(4) = 'geometry311.ini';
markerFiles(5) = 'geometry314.ini';
markerFiles(6) = 'geometry320.ini';

% create marker ids
expectedMarkerIDs = zeros(6,1); % Adjusted for conditional additions
expectedMarkerIDs(1) = 10002990; % reference marker
expectedMarkerIDs(2) = 10003010;
expectedMarkerIDs(3) = 10003020;
expectedMarkerIDs(4) = 10003110;
expectedMarkerIDs(5) = 10003140;
expectedMarkerIDs(6) = 10003200;


for k = 1:length(markerFiles)
    geom = loadGeometry(markerFiles(k));
    s.setGeometry(sn, geom);
end


%% <<prepositioning>>
bol_State = true;
bol_Error = false;
int_Counter = 0;
while bol_State

    int_Counter = int_Counter +1;

    if int_Counter == 20
        clc
        int_Counter = 0;
        [val,pos] = setdiff([s.geometries(sn).geometryId],[frame.markers.geometryId]);
        display("Error: Could not find Marker(s): "+  num2str(reshape(val',1,[]))  +" !")
	    pause(5)
    end


    frame = s.getlastFrame(sn);
    if length(frame.markers)>=length(expectedMarkerIDs)
        bol_State = false;

        display('Prepositioning worked!')
        pause(0.1)

    else
        display('Trying to find Markers.')
    end
    pause(0.1)
end

%% <<figure settings>>

%<<get frequency>>
db_Freq = str2num(winqueryreg('HKEY_CURRENT_USER', 'Motion Tracking', 'Frequency'));
db_Freq = 8;
display(['Record Frequency: ',num2str(db_Freq),' Hz'])


bol_Record = false;
int_RecordError = 0;
int_Count = 0;
%<<matlab loop>>
while winqueryreg('HKEY_CURRENT_USER', 'Motion Tracking', 'Matlab')
% while(1)
% bol_Test = true;
% while bol_Test


    int_Count = int_Count + 1;

    if int_Count == 1
        display('Tracking On (Not Recording)')
    end

    bol_Record = winqueryreg('HKEY_CURRENT_USER', 'Motion Tracking', 'Record');

    %<<loop record>>
    mat_Data = [];
    mat_DataRaw = [];
    try
        delete(obj_Patch1);
    end
    try
        delete(obj_Patch2);
    end
    try
        delete(obj_Patch3);
    end
    try
        delete(obj_Patch4);
    end


    %<<visualization>>
    frame = s.getlastFrame(sn);

    if and(~isempty(frame.markers),length(frame.markers)>=length(expectedMarkerIDs))
        display('Motion Tracking Working.');
    elseif isempty(frame.markers)
        display("Error: Could not find any Markers");
    else
        [val,~] = setdiff([s.geometries(sn).geometryId],[frame.markers.geometryId]);
        display("Error: Could not find Marker(s): "+  num2str(reshape(val',1,[]))  +" !")

    end

    tic
    while bol_Record

        %<<get tracking value>>
        frame = s.getlastFrame(sn);

        if and(~isempty(frame.markers),length(frame.markers)>=length(expectedMarkerIDs))

            latestTimestamp = toc;
            frame = s.getlastFrame(sn);

            markers = cell(1, length(expectedMarkerIDs));
            currentMarkerIDs = [frame.markers.geometryId];
            [currentMarkerIDs, sortIndx] = sort(currentMarkerIDs);
            for i = 1:length(sortIndx)
                markers{1, i} = frame.markers(sortIndx(i));
            end

            timestamp = sprintf('%06.f', latestTimestamp*100);
            nameString = [dataDIR filesep 'singleCapture' '_' timestamp '.mat'];
            % save(nameString, 'markers');
            time = latestTimestamp;
            save(nameString, 'markers', 'time');

            display(['Recording, markers saved to: ',nameString]);

        else
            [val,~] = setdiff([s.geometries(sn).geometryId],[frame.markers.geometryId]);
            display("Error: Could not find Marker(s): "+  num2str(reshape(val',1,[]))  +" !")
            % display('Record Error! (Not all Markers detected)')
            int_RecordError = int_RecordError+1;
        end


        bol_Record = winqueryreg('HKEY_CURRENT_USER', 'Motion Tracking', 'Record');%<<check if registy "record_on" still is enabled>>

        if bol_Record
            pause(1/db_Freq-(toc - latestTimestamp)-0.01);%<<correction value 0.01>>
        else
            if int_RecordError >0
                display(['Marker set was ',num2str(int_RecordError),' not visible.']);
            end
            if int_RecordError == 0
                display(['No recording errors.']);
            end
            pause(5)
            return
        end
    end
    pause(0.1)
end

close all
% exit

end

