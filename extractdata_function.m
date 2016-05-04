function [EXP, POS, CELL] = extractdata_function(handles, BKG)
% this function is called when pushing the EXTRACT button in extractdata_GUI
%
% this function, using input from the GUI or from the user himself, extracts data from segmentation.mat as phylocell v1.8 creates it




verbose = 0;


if verbose, fprintf(' extractdata_function e'' stata chiamata \n'); end

% open segmentation.mat
segmentation = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{handles.PositionNumber},'segmentation.mat'));

% creates output %
% % EXP  % %
EXP = struct('DeltaT',[],'NumberOfFrames',[]);
% DeltaT is
EXP.DeltaT = handles.DeltaT;
% NumberOfFrames is total frame number, as segmentation save it
EXP.NumberOfFrames = handles.LastFrame;
% Channel Numbers (CHANGE if more colors are available in the GUI)
EXP.RefCh       = handles.RefCh;
EXP.RedCh       = handles.RedCh;
EXP.GreenCh     = handles.GreenCh;
EXP.BlueCh      = handles.BlueCh;
EXP.YellowCh    = handles.YellowCh;
% ProjectData

%  - fields that can NOT be left empty but can be filled easily with segmentation
%    'ProjectName'      : the name of the project, that is the suffix for all the images folders and files
%    'channels'         : the channel number used, all together (NaNs can be or not present, is the same. no specific order is required)
%    'FirstFrame'       : the first frame of the movie, in number. usually 1
%    'LastFrame'        : the last frame of the movie, in number
%    'FirstMappedFrame' : the first mapped frame of the movie, in number (can be found as find(segmentation.cells1Mapped == 1, 1, 'first'))
%    'LastMappedFrame'  : the last mapped frame of the movie, in number  (can be found as find(segmentation.cells1Mapped == 1, 1, 'last')

EXP.ProjectName     = handles.PROJECT.realName;
EXP.ProjectFullPath = handles.PROJECT.realPath;
EXP.ProjectFullFile = fullfile(handles.PROJECT.realPath, strcat(handles.PROJECT.realName,'.mat'));
% Time is a vector containing the frame timing
EXP.Time        = EXP.DeltaT*[1:EXP.NumberOfFrames];
EXP.TimeUnits   = handles.TimeUnits;
%
EXP.Descr       = handles.ExpDescr;

% POS
p = handles.PositionNumber;
POS = struct();
POS(p).PositionNumber   = p;
POS(p).Strain           = handles.StrainNumber;
POS(p).FirstFrame       = handles.FirstFrame;
POS(p).LastFrame        = handles.LastFrame;
POS(p).FirstMappedFrame = handles.FirstMappedFrame;
POS(p).LastMappedFrame  = handles.LastMappedFrame;
POS(p).NumberOfCells    = size(nonzeros([segmentation.tcells1.N]),1);
% initialize variables for JoinMotherAndDaughter option
POS(p).JoinMotherAndDaughter = 'no';
POS(p).COUPLES = struct('frame',cell(1));
POS(p).MOTHERS = struct('frame',cell(1));
% if is asked to join mother and daughter, create the variables needed for it
if handles.JoinMotherAndDaughter
    POS(p).JoinMotherAndDaughter = 'yes';
    extractdata_CreateCouples
    POS(p).COUPLES = COUPLES;
    POS(p).MOTHERS = MOTHERS;
end
% if is asked to remove the background, write it
POS(p).RemoveBackground = 'no';
if handles.RemoveBackground
    POS(p).RemoveBackground = 'yes';
end



% % CELL % %
CELL = struct();
% creates fluorescence fields (with mean, min, max, sum and color)
CELL.FluoData = struct('Mean',[],'Min',[],'Max',[],'Sum',[],'LocInd',[],'RawData',{},'Color','');
FieldNames = fieldnames(CELL.FluoData);
for i = sort(handles.channels(~isnan(handles.channels)))
    % do not evaluate fluorescence if the channel is the reference one
    if i == handles.RefCh
        % all the cells with nonzeros N
        for NCell = nonzeros([segmentation.tcells1.N])'
            % put the right values in the fields
            for iField = 1:numel(FieldNames)
                FieldName = FieldNames{iField};
                if strcmp(FieldName,'Color'), continue; end
                CELL(NCell).FluoData(i).(FieldName) = [];
            end
            CELL(NCell).FluoData(i).Color = 'Ref';
        end
    else
        % for the other channels (non-reference ones): save fluorescence values from extract_fluorescence
        fprintf('  Extracting fluorescence for channel %d: ',i);
        temp = extract_fluorescence(handles, segmentation, i, POS(p).COUPLES, BKG);
        fprintf('\n');
        for NCell = 1: size(temp,2)
            CELL(NCell).FluoData(i) = temp(NCell);
        end
    end
end
%
%
%
% fill CELL data
for nCell = 1:size(segmentation.tcells1,2)
    % skip if a cell has number 0 (errors can occur)
    if ~segmentation.tcells1(nCell).N
        continue
    else
        NCell = segmentation.tcells1(nCell).N;
    end
    % REAL CELL
    CELL(NCell).n             = NCell;
    % POSITION
    CELL(NCell).Position      = handles.PositionNumber;
    % FRAMES
    % FirstFrame is birthFrame in segmentation
    CELL(NCell).FirstFrame    = segmentation.tcells1(nCell).birthFrame;
    % LastFrame is lastFrame in segmentation
    CELL(NCell).LastFrame     = segmentation.tcells1(nCell).lastFrame;
    % Area is a vector: it is NaN for frames when the cell weren't born or was already dead/out of image
    if NCell == 2
        
    end
    CELL(NCell).Area          = [nan(1,CELL(NCell).FirstFrame), [segmentation.tcells1(NCell).Obj.area], nan(1,EXP.NumberOfFrames - CELL(NCell).LastFrame)];
    % BUDDING, DAUGHTER and MOTHER
    % BudTimes are exactly the bud times as in segmentation..
    CELL(NCell).BudTimes      = segmentation.tcells1(NCell).budTimes;
    % ..the same for DivisionTimes..
    CELL(NCell).DivisionTimes = segmentation.tcells1(NCell).divisionTimes;
    % ..and for DaughterList
    CELL(NCell).DaughterList  = segmentation.tcells1(NCell).daughterList;
    % Mother is the number of this cell's mother
    CELL(NCell).Mother        = segmentation.tcells1(NCell).mother;
end
end
