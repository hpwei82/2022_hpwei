function handles = SettingTheROI(handles)
% Sets the ROI in which mean dF/F is calculated. 20180125 HK.

display('Click the center of the ROI in which mean dF/F is calculated.')

if isfield(handles,'rectangle') && ishandle(handles.rectangle)
    delete(handles.rectangle)
end

axes(handles.axes1);
[x, y] = ginput(1);

ImSize = handles.ImSize;
ImSize.ROIx = x - ImSize.ROIwidth/2;
ImSize.ROIy = y - ImSize.ROIheight/2;

handles.rectangle = rectangle('Position',[ImSize.ROIx,ImSize.ROIy,ImSize.ROIwidth,ImSize.ROIheight],...
	'EdgeColor', 'r',...
	'LineWidth', 3,...
	'LineStyle','-');

%% Save the data
handles.ImSize = ImSize;
