

function handles = RegisterAllTrialsSingle(handles)
% Creates the template as an average of baseline fluorescence in the first
% trial. 20180123 HK.

%% Load the parameters
ImSize = handles.ImSize;
OdorLabel = {'Ethyl butyrate','Mineral oil','4-methylcyclohexanol','Water'...
'Isopentyl acetate','2-pentanone','3-octanol','Benzaldehyde','Air'};
ColorPallet = [
  0,0,0;  
  255,0,0; 
  0,255,0; 
  0,0,255; 
  255,255,0; 
  0,255,255; 
  255,0,255; 
  192,192,192; 
  128,128,128; 
  128,0,0; 
  128,128,0; 
  0,128,0; 
  128,0,128; 
  0,128,128; 
  0,0,128
  220,220,220];
ColorPallet = ColorPallet/255;   % The number has to be between 0 and 1

%% Load each trail at a time, register, and extract dF/F within the ROI
DirOutputIndividual = dir(fullfile([handles.data.pathname '\*.lsm']));
FileNamesIndividual = {DirOutputIndividual.name}';
ImSize.nTrials = numel(FileNamesIndividual);    % number of files = number of trials

Signal = zeros([ImSize.nTFrames ImSize.nTrials]);
    
for l = 1:ImSize.nTrials;
    
    FileNameDirOutputIndividual = fullfile(handles.data.pathname,FileNamesIndividual{l});
    TemplateImage = tiffread30(FileNameDirOutputIndividual, []);
    
    sequenceOriginal = zeros([ImSize.nRows ImSize.nColumns ImSize.nTFrames],'double');
    
    % Create an image sequence array
    for t = 1:ImSize.nTFrames;
        sequenceOriginal(:,:,t) = TemplateImage(1,t).data;
    end
    
    sequence = sequenceOriginal;
    
    display(['Analyzing trial number ' num2str(l)])
    
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
    XYMovementRange = 30;      % Find the peak only in the vicinity of the center (center +- XYMovementRange) in the unit of pixel
    sequenceRegistered = sequence;
    
    %% Shift the images to maximize the correlation of coefficient between the first and the subsequent images
    %  Searches for the best matching frame within the range of 3 z slices (center +- 1).
    
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
    
    % Calculates mean signal within the ROI
    sequenceRegistered = sequenceRegistered(round(ImSize.ROIy):round(ImSize.ROIy)+ImSize.ROIheight,round(ImSize.ROIx):round(ImSize.ROIx)+ImSize.ROIwidth,:);  %[ROIwidth ROIheight ImSize.nTFrames]
    SignalTemp = squeeze(mean(sequenceRegistered,1));  %[ROIheight ImSize.nTFrames]
    SignalTemp = squeeze(mean(SignalTemp,1));  %[ImSize.nTFrames]
    Signal(:,l) = SignalTemp;  %[ImSize.nTFrames ImSize.nTrials]
end

%% Reorder trials and calculate the mean
% Reorder the trials
rng('default');
rng(handles.rngseed1); trialOrder(:,1) = randperm(ImSize.nOdors)';
rng(handles.rngseed2); trialOrder(:,2) = randperm(ImSize.nOdors)';
rng(handles.rngseed3); trialOrder(:,3) = randperm(ImSize.nOdors)';

for i = 1:ImSize.nBlocks
    SignalOrdered(:,trialOrder(:,i),i) = Signal(:,ImSize.nOdors*(i-1)+1:ImSize.nOdors*i);
end

meanSignal = mean(SignalOrdered,3);

%% Plot the data
figure;
for i = 1:ImSize.nOdors;
    subplot(3,3,i,'Fontsize',7);
    title(OdorLabel{i},'Fontsize',9);
    hold on;
    plot(meanSignal(:,i));
    axis([0 ImSize.nTFrames 0 max(max(meanSignal))+1]);
end

%% Save the 4D image
handles.meanSignal = meanSignal;

% newfilename = strrep(handles.data.pathname, [cd '\RawData\'],'');
Strs = strsplit(handles.data.pathname,filesep);
newfilename = Strs{end};

handles.data.newfilename = newfilename;
save([handles.data.pathname newfilename '_AnalyzedData' '.mat'],'meanSignal');
display('Image registration and analysis are done')
