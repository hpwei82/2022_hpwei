videoDir = uigetdir();

files = ReadFileNames(videoDir);
for j = 1:length(files)
    file = erase(files{j}, '.videodata');
    disp(file)
    data=readvideo(file);
    figure
    for i = 1	
        imagesc(data(:,:,i)');
    end	
    colormap gray			
    caxis([0,40])
    %# create AVI object	
    nFrames = 300;
    splitted_file = split(file, '\');
    save_name = strcat(strrep(splitted_file{length(splitted_file) - 2}, '#', '-'), '-', extractBetween(splitted_file{length(splitted_file)},1,3));
    save_path = strcat(strjoin(splitted_file(1:length(splitted_file) - 1),'\'), '\', strcat(save_name));
    vidObj = VideoWriter(save_path{1});	
    vidObj.Quality = 100;
    vidObj.FrameRate = 20;		
    open(vidObj);		
    %# create movie
    s = size(data);
    hold on	
    for i = 1:s(3)
        imagesc(data(:,:,i)');
        writeVideo(vidObj, getframe(gca));
    end
    close(gcf)
    %# save as AVI file, and open it using system video player
    close(vidObj);
end

function [ FList ] = ReadFileNames(DataFolder)
% Author: Thokare Nitin D.
% 
% This function reads all file names contained in Datafolder and it's subfolders
% with extension given in extList variable in this code...
% Note: Keep each extension in extension list with length 3
% i.e. last 3 characters of the filename with extension
% if extension is 2 character length (e.g. MA for mathematica ascii file), use '.'
% (i.e. '.MA' for given example)
% Example:
% extList={'jpg','peg','bmp','tif','iff','png','gif','ppm','pgm','pbm','pmn','xcf'};
% Gives the list of all image files in DataFolder and it's subfolder
% 
DirContents=dir(DataFolder);
FList=[];

if(strcmpi(computer,'PCWIN') || strcmpi(computer,'PCWIN64'))
    NameSeperator='\';
elseif(strcmpi(computer,'GLNX86') || strcmpi(computer,'GLNXA86'))
    NameSeperator='/';
end

extList={'videodata'};
% Here 'peg' is written for .jpeg and 'iff' is written for .tiff
for i=1:numel(DirContents)
    if(~(strcmpi(DirContents(i).name,'.') || strcmpi(DirContents(i).name,'..')))
        if(~DirContents(i).isdir)
%             extension=DirContents(i).name(end-2:end);
%             if(numel(find(strcmpi(extension,extList)))~=0)
            if endsWith(DirContents(i).name, extList{1})
                FList=cat(1,FList,{[DataFolder,NameSeperator,DirContents(i).name]});
            end
        else
            getlist=ReadFileNames([DataFolder,NameSeperator,DirContents(i).name]);
            FList=cat(1,FList,getlist);
        end
    end
end

end
