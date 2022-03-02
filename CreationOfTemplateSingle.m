function handles = CreationOfTemplateSingle(handles)
% Creates the template as an average of baseline fluorescence in the first
% trial. Timelapse imaging of a single z frame. 20180123 HK.

%% Set parameters
ImSize.nOdors = 9;              % number of odors
ImSize.nBlocks = 3;             % number of Blocks
ImSize.nTFramesBaseline = 10;   % number of time frames during the baseline period
ImSize.ROIwidth = 80;           % width of the ROI in which mean dF/F is calculated
ImSize.ROIheight = 40;          % height of the ROI in which mean dF/F is calculated

%% Load the first trail of the experiment
data.pathname = uigetdir([cd '\RawData'],...
    'Select the data folder to be analyzed');

DirOutputIndividual = dir(fullfile([data.pathname '\*.lsm']));
FileNamesIndividual = {DirOutputIndividual.name}';

FileNameDirOutputIndividual = fullfile(data.pathname,FileNamesIndividual{1});
TemplateImage = tiffread30(FileNameDirOutputIndividual, []);
I = TemplateImage(1,1).data;                    
ISize = size(I);
TemplateImageSize = size(TemplateImage);

ImSize.nRows = ISize(1,1);         % number of pixels along y axis
ImSize.nColumns = ISize(1,2);      % number of pixels along x axis
ImSize.nTFrames = TemplateImageSize(1,2);  % number of time frames

sequenceOriginal = zeros([ImSize.nRows ImSize.nColumns ImSize.nTFrames],'double');

% Create an image sequence array
for t = 1:ImSize.nTFrames;
    sequenceOriginal(:,:,t) = TemplateImage(1,t).data;
end

sequence = sequenceOriginal;

%% Smooth the image
GaussianFilterSize = 2;
GaussianFilterSigma = 1;
sequence = imfilter(sequence,fspecial('gaussian',[GaussianFilterSize GaussianFilterSize],GaussianFilterSigma));
FirstImage = sequence(:,:,1);

%% Remove this line later (this is used to check the performance of the function)
% sequence(:,:,5,5) = circshift(sequence(:,:,5,5),[3 3]);

%% Calculate the size of the image
Xsize = size(FirstImage,1);
Ysize = size(FirstImage,2);

%% Preallocate matrices and set the parameters
XYMovementRange = 10;      % Find the peak only in the vicinity of the center (center +- XYMovementRange) in the unit of pixel
sequenceRegistered = sequence;

%% Shift the images to maximize the correlation of coefficient between the first and the subsequent images

for i = 1:ImSize.nTFrames;
    Covariance = xcorr2(sequence(:,:,1),sequence(:,:,i))...
        /sqrt(sum(dot(sequence(:,:,1),sequence(:,:,1)))*sum(dot(sequence(:,:,i),sequence(:,:,i))));
    CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
    [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
    if length(Sx) ~= 1
        Sx = Sx(1,1);
        Sy = Sy(1,1);
    end
    ShiftSize = [Xsize-Sx,Ysize-Sy];
    sequenceRegistered(:,:,i)=circshift(sequenceOriginal(:,:,i),[-ShiftSize(1) -ShiftSize(2)]);
end

%% Save data
handles.ImSize = ImSize;
handles.template = mean(sequenceRegistered(:,:,1:ImSize.nTFramesBaseline),3);
handles.data.pathname = data.pathname;
display('Creation of a template is done')
