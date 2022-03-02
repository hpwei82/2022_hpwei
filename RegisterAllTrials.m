function handles = RegisterAllTrials(handles)
% Creates the template as an average of baseline fluorescence in the first
% trial. 20180123 HK.

%% Load the parameters
ImSize = handles.ImSize;
OdorLabel = {'Ethyl butyrate','Mineral oil','4-methylcyclohexanol','Water'...
'Isopentyl acetate','2-pentanone','3-octanol','Benzaldehyde','Air'};

%OdorLabel = {'Ethyl butyrate0.0001','Ethyl butyrate0.01','Ethyl butyrate1','Ethyl butyrate10'...
%'Ethyl butyrate50','Benzaldehyde0.0001','Benzaldehyde0.01','Benzaldehyde1','Benzaldehyde10','Benzaldehyde50','Mineral oil'};
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
    
    sequenceOriginal = zeros([ImSize.nRows ImSize.nColumns ImSize.nZSlices ImSize.nTFrames],'double');
    
    % Create an image sequence array
    for t = 1:ImSize.nTFrames;
        for i = 1:ImSize.nZSlices;
            sequenceOriginal(:,:,i,t) = TemplateImage(1,ImSize.nZSlices*(t-1)+i).data;
        end
    end
    
    sequence = sequenceOriginal;
    
    display(['Analyzing trial number ' num2str(l)])
    
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
    handles.CorrCoefInter2D = zeros(handles.ImSize.nTFrames,Zsize);
    handles.ShiftSizeInter2D = zeros(handles.ImSize.nTFrames,Zsize*2);
    handles.CorrCoefAfterInter2D = handles.CorrCoefInter2D;
%     XYMovementRange = 30;      % Find the peak only in the vicinity of the center (center +- XYMovementRange) in the unit of pixel
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
%                     CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
                    CovarianceCenter = Covariance;
                    [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
                    if length(Sx) ~= 1
                        Sx = Sx(1,1);
                        Sy = Sy(1,1);
                    end
                    TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
                    TemporaryShiftSize(k+1,:) = [Xsize-Sx,Ysize-Sy];
                    sequenceTemp(:,:,j+k,i)=circshift(sequence(:,:,j+k,i),[-TemporaryShiftSize(k+1,1) -TemporaryShiftSize(k+1,2)]);
                end
                
%                 CutSize = abs(max(TemporaryShiftSize(:)));
%                 for k = 0:1;
%                     Covariance = xcorr2(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),...
%                         sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k,i))...
%                         /sqrt(sum(dot(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1)))*...
%                         sum(dot(sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k,i),sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k,i))));
% %                     CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
%                     CovarianceCenter = Covariance;
%                     [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
%                     
%                     TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
%                 end
                
                [Maxk] = ind2sub(size(TemporaryCorrCoef),find(TemporaryCorrCoef==max(TemporaryCorrCoef(:))));
                
                handles.ShiftSizeInter2D(i,2*j-1:2*j) = [TemporaryShiftSize(Maxk,1),TemporaryShiftSize(Maxk,2)];
                handles.CorrCoefInter2D(i,j) = TemporaryCorrCoef(Maxk);
                
                sequenceRegistered(:,:,j,i) = circshift(sequenceOriginal(:,:,j+Maxk-1,i),[-TemporaryShiftSize(Maxk,1) -TemporaryShiftSize(Maxk,2)]);
                
            elseif ((1 < j) && (j < Zsize));
                for k = 0:2;
                    Covariance = xcorr2(sequence(:,:,j,1),sequence(:,:,j+k-1,i))...
                        /sqrt(sum(dot(sequence(:,:,j,1),sequence(:,:,j,1)))*sum(dot(sequence(:,:,j+k-1,i),sequence(:,:,j+k-1,i))));
%                     CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
                    CovarianceCenter = Covariance;
                    [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
                    if length(Sx) ~= 1
                        Sx = Sx(1,1);
                        Sy = Sy(1,1);
                    end
                    TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
                    TemporaryShiftSize(k+1,:) = [Xsize-Sx,Ysize-Sy];
                    sequenceTemp(:,:,j+k-1,i)=circshift(sequence(:,:,j+k-1,i),[-TemporaryShiftSize(k+1,1) -TemporaryShiftSize(k+1,2)]);
                end
                
%                 CutSize = abs(max(TemporaryShiftSize(:)));
%                 for k = 0:2;
%                     Covariance = xcorr2(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),...
%                         sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))...
%                         /sqrt(sum(dot(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1)))*...
%                         sum(dot(sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i),sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))));
% %                     CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
%                     CovarianceCenter = Covariance;
%                     [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
%                     
%                     TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
%                 end
                
                [Maxk] = ind2sub(size(TemporaryCorrCoef),find(TemporaryCorrCoef==max(TemporaryCorrCoef(:))));
                
                handles.ShiftSizeInter2D(i,2*j-1:2*j) = [TemporaryShiftSize(Maxk,1),TemporaryShiftSize(Maxk,2)];
                handles.CorrCoefInter2D(i,j) = TemporaryCorrCoef(Maxk);
                
                sequenceRegistered(:,:,j,i) = circshift(sequenceOriginal(:,:,j+Maxk-2,i),[-TemporaryShiftSize(Maxk,1) -TemporaryShiftSize(Maxk,2)]);
                
            else
                clear TemporaryCorrCoef TemporaryShiftSize;
                for k = 0:1;
                    Covariance = xcorr2(sequence(:,:,j,1),sequence(:,:,j+k-1,i))...
                        /sqrt(sum(dot(sequence(:,:,j,1),sequence(:,:,j,1)))*sum(dot(sequence(:,:,j+k-1,i),sequence(:,:,j+k-1,i))));
%                     CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
                    CovarianceCenter = Covariance;
                    [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
                    if length(Sx) ~= 1
                        Sx = Sx(1,1);
                        Sy = Sy(1,1);
                    end
                    TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
                    TemporaryShiftSize(k+1,:) = [Xsize-Sx,Ysize-Sy];
                    sequenceTemp(:,:,j+k-1,i)=circshift(sequence(:,:,j+k-1,i),[-TemporaryShiftSize(k+1,1) -TemporaryShiftSize(k+1,2)]);
                end
                
%                 CutSize = abs(max(TemporaryShiftSize(:)));
%                 for k = 0:1;
%                     Covariance = xcorr2(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),...
%                         sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))...
%                         /sqrt(sum(dot(sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1),sequence(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j,1)))*...
%                         sum(dot(sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i),sequenceTemp(CutSize+1:Xsize-CutSize,CutSize+1:Ysize-CutSize,j+k-1,i))));
% %                     CovarianceCenter = Covariance((Xsize-XYMovementRange):(Xsize+XYMovementRange),(Ysize-XYMovementRange):(Ysize+XYMovementRange));
%                     CovarianceCenter = Covariance;
%                     [Sx,Sy] = ind2sub(size(Covariance),find(Covariance==max(CovarianceCenter(:))));
%                     
%                     TemporaryCorrCoef(k+1,:) = max(CovarianceCenter(:));
%                 end
                
                [Maxk] = ind2sub(size(TemporaryCorrCoef),find(TemporaryCorrCoef==max(TemporaryCorrCoef(:))));
                
                handles.ShiftSizeInter2D(i,2*j-1:2*j) = [TemporaryShiftSize(Maxk,1),TemporaryShiftSize(Maxk,2)];
                handles.CorrCoefInter2D(i,j) = TemporaryCorrCoef(Maxk);
                
                sequenceRegistered(:,:,j,i) = circshift(sequenceOriginal(:,:,j+Maxk-2,i),[-TemporaryShiftSize(Maxk,1) -TemporaryShiftSize(Maxk,2)]);
            end
        end
    end
    
    % Calculates mean signal within the ROI
    sequenceRegistered = squeeze(sequenceRegistered(:,:,handles.LastSliderFrame,:));  %[ImSize.nRows ImSize.nColumns ImSize.nZSlices ImSize.nTFrames]
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
    subplot(3,5,i,'Fontsize',7);
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
