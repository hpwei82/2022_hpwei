function handles = CreationOfTemplate(handles)
% Creates the template as an average of baseline fluorescence in the first
% trial. 20170123 HK.

%% Set parameters
ImSize.nOdors = 9;              % number of odors
ImSize.nBlocks = 3;             % number of Blocks
ImSize.nZSlices = 5;            % number of z slices
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
ImSize.nTFrames = TemplateImageSize(1,2)/ImSize.nZSlices;  % number of time frames

sequenceOriginal = zeros([ImSize.nRows ImSize.nColumns ImSize.nZSlices ImSize.nTFrames],'double');

% Create an image sequence array
for t = 1:ImSize.nTFrames;
    for i = 1:ImSize.nZSlices;
        sequenceOriginal(:,:,i,t) = TemplateImage(1,ImSize.nZSlices*(t-1)+i).data;
    end
end

sequence = sequenceOriginal;

%% Smooth the image
GaussianFilterSize = 2;
GaussianFilterSigma = 1;
sequence = imfilter(sequence,fspecial('gaussian',[GaussianFilterSize GaussianFilterSize],GaussianFilterSigma));
FirstImage = sequence(:,:,:,1);

%% Remove this line later (this is used to check the performance of the function)
% sequence(:,:,5,5) = circshift(sequence(:,:,5,5),[3 3]);

%% Calculate the size of the image
Xsize = size(FirstImage,1);
Ysize = size(FirstImage,2);
Zsize = size(FirstImage,3);

%% Preallocate matrices and set the parameters
handles.CorrCoefInter2D = zeros(ImSize.nTFrames,Zsize);
handles.ShiftSizeInter2D = zeros(ImSize.nTFrames,Zsize*2);
handles.CorrCoefAfterInter2D = handles.CorrCoefInter2D;
XYMovementRange = 10;      % Find the peak only in the vicinity of the center (center +- XYMovementRange) in the unit of pixel
sequenceTemp = sequence;
sequenceRegistered = sequence;

%% Shift the images to maximize the correlation of coefficient between the first and the subsequent images
%  Searches for the best matching frame within the range of 3 z slices (center +- 1).

for i = 1:ImSize.nTFrames;
    for j = 1:Zsize;
        if j == 1;
            for k = 0:1;
                Covariance = xcorr2(sequence(:,:,j,1),sequence(:,:,j+k,i))...
                    /sqrt(sum(dot(sequence(:,:,j,1),sequence(:,:,j,1)))*sum(dot(sequence(:,:,j+k,i),sequence(:,:,j+k,i))));
                CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
                [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
                if length(Sx) ~= 1
                    Sx = Sx(1,1);
                    Sy = Sy(1,1);
                end
                TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
                TemporaryShiftSize(k+1,:) = [Xsize-Sx,Ysize-Sy];
                sequenceTemp(:,:,j+k,i)=circshift(sequence(:,:,j+k,i),[-TemporaryShiftSize(k+1,1) -TemporaryShiftSize(k+1,2)]);
            end
            
%             CutSize = abs(max(TemporaryShiftSize(:)));
%             for k = 0:1;
%                 Covariance = xcorr2(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),...
%                     sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k,i))...
%                     /sqrt(sum(dot(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1)))*...
%                     sum(dot(sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k,i),sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k,i))));
%                 CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
%                 [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
%                 
%                 TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
%             end
            
            [Maxk] = ind2sub(size(TemporaryCorrCoef),find(TemporaryCorrCoef==max(TemporaryCorrCoef(:))));
            
            handles.ShiftSizeInter2D(i,2*j-1:2*j) = [TemporaryShiftSize(Maxk,1),TemporaryShiftSize(Maxk,2)];
            handles.CorrCoefInter2D(i,j) = TemporaryCorrCoef(Maxk);
            
            sequenceRegistered(:,:,j,i) = circshift(sequenceOriginal(:,:,j+Maxk-1,i),[-TemporaryShiftSize(Maxk,1) -TemporaryShiftSize(Maxk,2)]);
            
        elseif ((1 < j) && (j < Zsize));
            for k = 0:2;
                Covariance = xcorr2(sequence(:,:,j,1),sequence(:,:,j+k-1,i))...
                    /sqrt(sum(dot(sequence(:,:,j,1),sequence(:,:,j,1)))*sum(dot(sequence(:,:,j+k-1,i),sequence(:,:,j+k-1,i))));
                CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
                [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
                if length(Sx) ~= 1
                    Sx = Sx(1,1);
                    Sy = Sy(1,1);
                end
                TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
                TemporaryShiftSize(k+1,:) = [Xsize-Sx,Ysize-Sy];
                sequenceTemp(:,:,j+k-1,i)=circshift(sequence(:,:,j+k-1,i),[-TemporaryShiftSize(k+1,1) -TemporaryShiftSize(k+1,2)]);
            end
            
%             CutSize = abs(max(TemporaryShiftSize(:)));
%             for k = 0:2;
%                 Covariance = xcorr2(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),...
%                     sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))...
%                     /sqrt(sum(dot(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1)))*...
%                     sum(dot(sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i),sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))));
%                 CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
%                 [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
%                 
%                 TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
%             end
            
            [Maxk] = ind2sub(size(TemporaryCorrCoef),find(TemporaryCorrCoef==max(TemporaryCorrCoef(:))));
            
            handles.ShiftSizeInter2D(i,2*j-1:2*j) = [TemporaryShiftSize(Maxk,1),TemporaryShiftSize(Maxk,2)];
            handles.CorrCoefInter2D(i,j) = TemporaryCorrCoef(Maxk);
            
            sequenceRegistered(:,:,j,i) = circshift(sequenceOriginal(:,:,j+Maxk-2,i),[-TemporaryShiftSize(Maxk,1) -TemporaryShiftSize(Maxk,2)]);    
            
        else
            clear TemporaryCorrCoef TemporaryShiftSize;
            for k = 0:1;
                Covariance = xcorr2(sequence(:,:,j,1),sequence(:,:,j+k-1,i))...
                    /sqrt(sum(dot(sequence(:,:,j,1),sequence(:,:,j,1)))*sum(dot(sequence(:,:,j+k-1,i),sequence(:,:,j+k-1,i))));
                CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
                [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
                if length(Sx) ~= 1
                    Sx = Sx(1,1);
                    Sy = Sy(1,1);
                end
                TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
                TemporaryShiftSize(k+1,:) = [Xsize-Sx,Ysize-Sy];
                sequenceTemp(:,:,j+k-1,i)=circshift(sequence(:,:,j+k-1,i),[-TemporaryShiftSize(k+1,1) -TemporaryShiftSize(k+1,2)]);
            end
            
%             CutSize = abs(max(TemporaryShiftSize(:)));
%             for k = 0:1;
%                 Covariance = xcorr2(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),...
%                     sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))...
%                     /sqrt(sum(dot(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1)))*...
%                     sum(dot(sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i),sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))));
%                 CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
%                 [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
%                 
%                 TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
%             end
            
            [Maxk] = ind2sub(size(TemporaryCorrCoef),find(TemporaryCorrCoef==max(TemporaryCorrCoef(:))));
            
            handles.ShiftSizeInter2D(i,2*j-1:2*j) = [TemporaryShiftSize(Maxk,1),TemporaryShiftSize(Maxk,2)];
            handles.CorrCoefInter2D(i,j) = TemporaryCorrCoef(Maxk);
            
            sequenceRegistered(:,:,j,i) = circshift(sequenceOriginal(:,:,j+Maxk-2,i),[-TemporaryShiftSize(Maxk,1) -TemporaryShiftSize(Maxk,2)]);
        end
    end
end

%% Save data
handles.ImSize = ImSize;
handles.template = mean(sequenceRegistered(:,:,:,1:ImSize.nTFramesBaseline),4);
handles.data.pathname = data.pathname;
display('Creation of a template is done')
