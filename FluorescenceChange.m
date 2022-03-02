function handles = FluorescenceChange(handles)
%% set a parameter
NumberOfBaseline = 9;                  % number of cycles to calculate the baseline

%% load the 4D image
sequence = handles.sequenceTimeSeries;

%% Smooth using a Gaussian kernel
GaussianFilterSize = 2;
GaussianFilterSigma = 1;
sequence = imfilter(sequence,fspecial('gaussian',[GaussianFilterSize GaussianFilterSize],GaussianFilterSigma));
DeltaFOverF = sequence;

%% Calculate baseline image
BaselineImage = mean(sequence(:,:,:,8:NumberOfBaseline),4);
BaselineImage(BaselineImage<10)=100000;     % This step is included to make the background dark

%% Calculate deltaF over F and create a movie
for i = 1:handles.ImSize.numTFrames;
    DeltaFOverF(:,:,:,i) = (sequence(:,:,:,i)-BaselineImage)./BaselineImage*100;
    MaxProjection(:,:,i) = max(DeltaFOverF(:,:,:,i),[],3);
%     MaxProjection(:,:,i) = mean(DeltaFOverF(:,:,:,i),3);
    imshow(MaxProjection(:,:,i),[-50 400]);
    MaxProjectionMovie(i) = getframe;
   
    % Creation of 3D movie
%     D = int8(DeltaFOverF(:,:,:,i));
%     figure;
%     h = gca;
%     vol3d('cdata',D,'texture','3D');
%     view(3);
%     set(h,'xlim',[0 64],'ylim',[0 64]);
%     colormap(gray);
%     alphamap(0.1.*alphamap);
%     DeltaFOverFMovie(i) = getframe;
%     close;
end

%% Save movies
handles.MaxProjectionMovie = MaxProjectionMovie;
handles.DeltaFOverF = DeltaFOverF;
% movie2avi(MaxProjectionMovie,'movie.avi','compression','None','fps',5);
% handles.DeltaFOverFMovie = DeltaFOverFMovie;

display('Calculation is done')

% % implay(DeltaFOverF(:,:,:,10))
% D = int8(DeltaFOverF(:,:,:,8));
% % D = sequence(:,:,:,10);
% figure;
% h = vol3d('cdata',D,'texture','3D');
% view(3);
% colormap(gray);
% alphamap(.1 .* alphamap);
% display('Calculation is done.');
% h1=gcf;
% h1a=allchild(gca);
% copyobj(h1a,handles.axes1);   % copying the figure to an axes in ImageRegistrationGUI
% set(handles.axes1,'xlim',[0 64],'ylim',[0 64]);
% colormap(handles.axes1,gray);
% alphamap(handles.axes1,0.1.*alphamap);
% colorbar('peer',handles.axes1,'East');