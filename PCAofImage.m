function handles = PCAofImage(handles)
%% Perform Principal component analysis
Response = zeros(handles.ImSize.numTFrames, size(handles.DeltaFOverF,1)*size(handles.DeltaFOverF,2)*size(handles.DeltaFOverF,3));
for i = 1:handles.ImSize.numTFrames;
    TimeCycle = handles.DeltaFOverF(:,:,:,i);
    Response(i,:) = TimeCycle(:)';
end

%% PCA using pca.m
% http://www.mathworks.com/matlabcentral/fileexchange/21524-principal-component-analysis
tic;
[U,S,V] = pca(zscore(Response));
score1 = U*S;
toc;
figure;
plot3(score1(:,1),-score1(:,2),-score1(:,3),'g.');
hold on;
plot3(score1(:,1),-score1(:,2),-score1(:,3));
display('PCA is done')

%% PCA using princomp
% tic;
% [coef,score,latent,tsquare] = princomp(zscore(Response));
% toc;
% figure;
% plot3(score(:,1),score(:,2),score(:,3),'r.');
% hold on;
% plot3(score(:,1),score(:,2),score(:,3));
% display('PCA is done')
end