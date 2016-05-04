function  BKG         = extractdata_background(handles)
% this function returns a structure with one field per fluorescence channel
% these fields are vectors of mean fluorescence, computed over a non-segmented area in the image

% BKG(ChNumber).Mean(frame)

segmentation = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{handles.PositionNumber},'segmentation.mat'));

BKG = struct('Mean',nan(handles.LastFrame,1),'Color','');
for ChNumber = sort(handles.channels(~isnan(handles.channels)))
 % do not evaluate fluorescence if the channel is the reference one
 if ChNumber == handles.RefCh
   BKG(ChNumber).Mean  = nan(handles.LastFrame,1);
   BKG(ChNumber).Color = 'Ref';
 else
  % if i doesn't indicate the Reference channel: go on computing the background
  %  initialize BKG
  BKG(ChNumber).Mean = nan(handles.LastFrame,1);  
  % this is the images folder path
  imgsPath   = fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.channels{handles.PositionNumber,ChNumber});
  for f = handles.FirstFrame:handles.LastFrame
   if ~mod(f,5), fprintf('*'); end
   % if frame f is out of the mapped part of the movie, put NaN
   if f < handles.FirstMappedFrame || f > handles.LastMappedFrame
    BKG(ChNumber).Mean(f) = NaN;
    continue;
   end
   % open the right image (project, position, channel, frame)
   F = imread(fullfile(imgsPath,strcat(handles.PROJECT.pathList.names{handles.PositionNumber,ChNumber},'-',num2str(f,'%03.f'),'.jpg')));
   % initialize cellMask as empty
   CellMask  = zeros(size(F));
   % nCell will cycle over the segmentation.cells1 indexes corresponding to nonzeros .n fields
   for nCell = find([segmentation.cells1(f,:).n]>0)
    xCell = segmentation.cells1(f,nCell).x;      yCell = segmentation.cells1(f, nCell).y;
    mask  = poly2mask(xCell,yCell,size(F,1),size(F,2));
    CellMask = CellMask + mask;
   end
   % normalize CellMask: either 0 or 1 (it could me more than one in an index if segmentations overlap)
   CellMask = im2bw(CellMask, 0.5);
   % take all the pixels segmented from image F (via multiplying the images)
   CellMask   = double(immultiply(uint16(CellMask),F));
   % take all the pixels that are NOT segmented (all out of cells) from image F (via multiplying the images)
   NoCellMask = double(immultiply(uint16(~CellMask),F));
   
   % % take the mean of these non-segmented pixels, and round this number to the closest integer
   BKG(ChNumber).Mean(f) = round(mean(nonzeros(NoCellMask)));
   
   
  end
  
  %
  % give the right color name for this channel
  fields = fieldnames(handles);
  for i = 1:numel(fields)
   % find fields in handles whose last two letters are 'Ch'
   if regexp(fields{i},'Ch') == (size(fields{i},2) - 2 +1)
    if ChNumber == handles.(fields{i})
     break
    end
   end
  end
  % get the color (as a string)
  Color = fields{i}(1:(end-2));
  BKG(ChNumber).Color = Color;
 end
end





