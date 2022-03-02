function handles = ThreeDimensionalRegistration(handles)
%% Load the 4D image
display('Registering images. Please wait...')
sequence = handles.sequenceTimeSeries;
FirstImage = sequence(:,:,:,1);

%% Remove this line later (this is used to check the performance of the function)
% sequence(:,:,:,2) = circshift(sequence(:,:,:,2),[18 18 2]);

%% Calculate the center of the image
Xcenter = size(FirstImage,1)/2;
Ycenter = size(FirstImage,2)/2;

if (mod(size(FirstImage,3),2) == 0)
    Zcenter = size(FirstImage,3)/2;
else
    Zcenter = (size(FirstImage,3)+1)/2;
end

%% Preallocate matrices
% u16max = 2^16-1;
handles.CorrCoef = zeros(handles.ImSize.numTFrames,1);
handles.ShiftSize = zeros(handles.ImSize.numTFrames,3);
handles.CorrCoefAfter = handles.CorrCoef;

%% Shift the images to maximize the correlation of coefficient between the first and the subsequent images
for i = 1:handles.ImSize.numTFrames;
    SelectedImage = sequence(:,:,:,i);
    [I_NCC]=template_matching_gray(FirstImage,SelectedImage,[]);
    [Sx,Sy,Sz]=ind2sub(size(I_NCC),find(I_NCC==max(I_NCC(:))));
    
    ShiftSizeX = Xcenter - Sx;
    ShiftSizeY = Ycenter - Sy;
    ShiftSizeZ = Zcenter - Sz;
    
    handles.ShiftSize(i,:) = [ShiftSizeX,ShiftSizeY,ShiftSizeZ];
    handles.CorrCoef(i) = max(I_NCC(:));
    
    sequence(:,:,:,i) = circshift(sequence(:,:,:,i),[ShiftSizeX ShiftSizeY ShiftSizeZ]);
    
    [I_NCC]=template_matching_gray(FirstImage,sequence(:,:,:,i),[]);
    [Sx,Sy,Sz]=ind2sub(size(I_NCC),find(I_NCC==max(I_NCC(:))));
    handles.CorrCoefAfter(i) = max(I_NCC(:));
    
%     I = sequence(:,:,:,i);
%     I = (I - min(min(min(I))))/(max(max(max(I))) - min(min(min(I))));
%     I = int16(I*u16max - 2^16/2);
%     sequence(:,:,:,i) = I;
end

%% Save the 4D image
handles.sequenceTimeSeries = sequence;
display('Image registration is done')
