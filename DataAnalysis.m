function [data] = DataAnalysis(varargin)
% Assembles and analyzes data taken in multiple experiments

%% Set the parameter
BaselineStart = 8;
BaselineEnd = 10;
ResponseStart = 13;
ResponseEnd = 20;
AcquisitionTime = 0.5;    % Duration of one time frame in seconds
 OdorLabel = {'Ethyl butyrate','EtOH','4-methylcyclohexanol','ba4'...
 'ba1','ba2','ba3','ba5','Air',};
% OdorLabel = {'Ethyl butyrate','Mineral oil','4-methylcyclohexanol','Water'...
% 'Isopentyl acetate','2-pentanone','3-octanol','Benzaldehyde','Air',};
%OdorLabel = {'Ethyl butyrate0.0001','Ethyl butyrate0.01','Ethyl butyrate1','Ethyl butyrate10'...
%'Ethyl butyrate50','Benzaldehyde0.0001','Benzaldehyde0.01','Benzaldehyde1','Benzaldehyde10','Benzaldehyde50','Mineral oil'};

%% Select the folder, load data, and calculate DF/F
data.pathname = uigetdir([cd '\AnalyzedData'],...
    'Select the data folder to be analyzed');

DirOutputIndividual = dir(fullfile([data.pathname '\*.mat']));
FileNamesIndividual = {DirOutputIndividual.name}';
nBrains = numel(FileNamesIndividual);
load(FileNamesIndividual{1});  % meanSignal is loaded
nTFrames = size(meanSignal,1);
nOdors = size(meanSignal,2);
DeltaFOverF = zeros([nOdors nTFrames nBrains]);

for i = 1:nBrains
    load(FileNamesIndividual{i});
    meanSignal = meanSignal';  % [nOdors nTFrames]
    Baseline = mean(meanSignal(:,BaselineStart:BaselineEnd),2);
    if strcmp(FileNamesIndividual{i},'20170824-1-gr5a-3d-s24-palps glued20170824-1-gr5a-3d-s24-palps glued_AnalyzedData.mat')
        meanSignal = meanSignal(:,1:60);
        nTFrames = 60;
    end
    for j = 1:nTFrames
        DeltaFOverF(:,j,i) = (meanSignal(:,j)-Baseline)./Baseline*100;
    end
end

peakResponse = squeeze(mean(DeltaFOverF(:,ResponseStart:ResponseEnd,:),2));  %[nOdors nBrains]

%% Spectral analysis
SamplingFreq = 1/AcquisitionTime;

OneDimDeltaFOverF = DeltaFOverF(:,BaselineStart:BaselineEnd,:);
OneDimDeltaFOverF = OneDimDeltaFOverF(:);
Y = fft(OneDimDeltaFOverF,numel(OneDimDeltaFOverF));
Pyy = Y.*conj(Y)/numel(OneDimDeltaFOverF);
f = SamplingFreq/numel(OneDimDeltaFOverF)*(0:numel(OneDimDeltaFOverF)/2+1);
plot(f,Pyy(1:numel(OneDimDeltaFOverF)/2+2))
title('Power spectral density')
xlim([0 SamplingFreq/2]);
xlabel('Frequency (Hz)')

%% Plot the data
% 1 Plot individual traces
figure;
for i = 1:nOdors
    subplot(3,3,i,'Fontsize',7);
    title(OdorLabel{i},'Fontsize',9);
    hold on;
    for j = 1:nBrains;
        plot(DeltaFOverF(i,:,j),'color',[0.7 0.7 0.7]);
        hold on;
    end
    hold on;
    input = mean(DeltaFOverF(i,:,:),3);
    plot(input,'color',[0 0 0]);
    axis([0 nTFrames min(min(min(DeltaFOverF)))-20 max(max(max(DeltaFOverF)))+20]);
end


% 2 Plot mean plus minus SD traces
figure;
for i = 1:nOdors
    subplot(3,3,i,'Fontsize',7);
    title(OdorLabel{i},'Fontsize',9);
    hold on;
    input = squeeze(DeltaFOverF(i,:,:))';
    myeb(input);
    axis([0 nTFrames min(min(min(DeltaFOverF)))-20 max(max(max(DeltaFOverF)))+20]);
end

% 3 Scatter plot of individual and mean peak responses
figure;
ScatterPlotIndividualAndMean(peakResponse);
hold on;

plot(0:nOdors+1,zeros(1,nOdors+2),'--','color',[0.7 0.7 0.7]);
axis([0 nOdors+1,min(min(min(peakResponse)))-20 max(max(max(peakResponse)))+20]);
xlabel('Odor identity');
ylabel('DF/F');


%% Save the data
data.DeltaFOverF = DeltaFOverF;

save([data.pathname 'AverageOf' num2str(nBrains) '.mat'],'data');


