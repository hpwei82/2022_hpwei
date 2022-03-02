function handles = OpenImages(handles)
%% Set parameters

ImSize.PixelSizeTimeSeries = 1.581;     % pixel size in microns
ImSize.SliceThicknessTimeSeries = 3;    % pixel thickness in microns
ImSize.numTFrames = 20;                 % number of time cycles

%% Open the 4D image

TimeSeriesDir = uigetdir('C:\Users\Kazama\Documents\Hokto\Zeiss imaging data\pebbled120329MET');
handles.FileFolder.TimeSeries = fullfile(TimeSeriesDir);
DirOutputTimeSeries = dir(fullfile(handles.FileFolder.TimeSeries,'*.tif'));
FileNamesTimeSeries = {DirOutputTimeSeries.name}';
numTFrames = ImSize.numTFrames;
numFramesTimeSeries = numel(FileNamesTimeSeries);          % numel: number of elements
numZFramesTimeSeries = numFramesTimeSeries/numTFrames;

% Create an image sequence array (y,x,z,t)
J = imread(FileNamesTimeSeries{1});
sequenceTimeSeries = zeros([size(J) numZFramesTimeSeries numTFrames],class(J));
s = 1;
for q = 1:numZFramesTimeSeries
    for p = 1:numTFrames
        sequenceTimeSeries(:,:,(numZFramesTimeSeries-q+1),p) = imread(FileNamesTimeSeries{s});
        s=s+1;
    end
end

%% Save parameters
ImSize.NumRows = size(J,1);
ImSize.numZFramesTimeSeries = numZFramesTimeSeries;

handles.ImSize = ImSize;
handles.sequenceTimeSeries = double(sequenceTimeSeries);
display('Opened the image')
