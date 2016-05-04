function varargout = extractdata_GUI(varargin)
% this GUI is called by extractdata.m, if no input arguments are given.
% it is a user friendly interface where user can give inputs for extracting data from a phylocell project.
% user must specify the project, the position and some details about the acquisition (number for fluorescence channels, time between frames),
%  so to create the output variables.
% this function returns three variables: EXP, POS and CELL.
%  EXP:
%   this is a structure, and contains all the information about the experiment, so it is ideally identical for different position of the same experiment.
%   'DeltaT'
%    'NumberOfFrames'
%    'RefCh'
%    'RedCh'
%    'GreenCh'
%    'BlueCh'
%    'YellowCh'
%    'ProjectName'
%    'ProjectFullPath'
%    'Time'
%    'TimeUnits'
%    'Descr'
%
%  POS:
%   this variable is a structure, and contains the info about the position specified.
%   it is numbered as the position number itself, even if a single position has been analyzed
%   (if user want to extract data for position 2, POS will be a struct 1x2, with POS(1) empty).
%   in this way is easier to join all the position information together.
%   these are its field names:
%    'Number'
%    'Strain'
%    'FirstMappedFrame'
%    'LastMappedFrame'
%    'NumberOfCells'
%    'Background'
%    'CellData'
%   the most interesting fields are Background and CellData.
%   Background is a structure with a position per channel number.
%   in every one of them there is an array containing the mean value of the non-segmented part of the image for the corresponding channel.
%   that is: POS.Background(2).Mean is an array of the same length of the movie,
%   containing in every column the mean value of the non-segmented part of the image for channel 2.
%
%   CellData contains the information about every cell for the given position, numbered as phylocell numbers cells.
%   it is exactly the same struct as CELL will be, but nested in POS can be later joined to the cell information from other positions.
%   CellData is easily indexed: POS(2).CellData(15) contains all the information extracted for cell 15 in position 2.
%   also this field is a structure, with the following fields:
%    'FluoData'
%    'Position'
%    'FirstFrame'
%    'LastFrame'
%    'Area'
%    'BudTimes'
%    'DivisionTimes'
%    'DaughterList'
%    'Mother'
%   in the field FluoData there are the infos about the fluorescence values, per channel.
%   so: POS(2).CellData(15).FluoData(2).Mean will contain the mean values for channel 2 for cell 15 in position 2.



% %
% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @extractdata_GUI_OpeningFcn, ...
    'gui_OutputFcn',  @extractdata_GUI_OutputFcn, ...
    'gui_LayoutFcn',  [], ...
    'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
% %

% % % % % % % % % %
% OPENING THE GUI %
% % % % % % % % % %
% --- Executes just before extractdata_GUI is made visible.
function extractdata_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% Choose default command line output for extractdata_GUI
handles.output = cell(1);   handles.output{1} = hObject;
% create 'check' field in handles to save input check flags, and initialize them to 0
handles.check = struct();
handles.check.position = 0;
handles.check.channels = 0;
handles.check.deltat   = 0;

handles.ProjectName = '';
handles.VarName = '';
handles.VarPath = '';

handles.TimeUnits = 'min';

% hExtractMainGui is the handle for this GUI, in order to get back the data saved using setappdata
setappdata(0, 'hExtractMainGui', gcf);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes extractdata_GUI wait for user response (see UIRESUME)
if false,  fprintf('mi son fermato \n'); end
uiwait(handles.figure1);

% % % % % % % % % %
% CLOSING THE GUI %
% % % % % % % % % %
% --- Executes when user attempts to close figure1.
function figure1_CloseRequestFcn(hObject, eventdata, handles)
%When user clicks button, check to see if GUI is in wait  %mode. If it is, resume program; otherwise close GUI
if isequal(get(hObject, 'waitstatus'), 'waiting')
    uiresume(hObject);
    if false, fprintf('ho ricominciato \n'); end
    
else
    delete(hObject);
    if false, fprintf('ho chiuso \n'); end
end


% --- Outputs from this function are returned to the command line.
function varargout = extractdata_GUI_OutputFcn(hObject, eventdata, handles)
handles = guihandles;
handles = guidata(hObject);
% handles.output is defined in the function ExtractData_Callback, in this same script
varargout = handles.output;



% % % % % % % % %
% % CALLBACKS % %
% % % % % % % % %

% --- Executes on button press in ProjectFileButt.
function ProjectFileButt_Callback(hObject, eventdata, handles)
% hObject    handle to ProjectFileButt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
[ProjectName, ProjectPath]  = uigetfile('*.mat','Select phylocell project file');
% if ProjectName is not 0 (it is 0 if user canceled)
if ProjectName
    PROJECT = importdata(fullfile(ProjectPath, ProjectName));
    % check: is it a correct phylocell project?
    if isfield(PROJECT,'numberOfFrames')
        % write in the blank space the full path of the file (for the user to control it)
        set(handles.ProjectFilePath,'string',fullfile(ProjectPath, ProjectName));
        % save the file (not the name!) in handles.PROJECT
        handles.PROJECT     = PROJECT;
        % substitute the path as saved in the PROJECT file with the real ones
        %  (there could be problems since phylocell only saves paths when the project is created:
        %   if project file has been moved or folder name has changed, no way to know it.
        %   phylocell uses the same
        handles.PROJECT.path     = ProjectPath;
        handles.PROJECT.realPath = ProjectPath;
        % ProjectName is saved after, during the position number call, by an external function
        %  (the same extractdata calls with all the adequate input)
        
        % check: project file is ok
        handles.check.project = 1;
        %
        % enable acquisition setting fields and set color as it should be (green for green channel and so on..)
        numCh = size(handles.PROJECT.pathList.channels,2);
        strCh = textscan(num2str(1:numCh),'%s'); strCh = strCh{1};
        set(handles.GreenChannelMenu,   'Enable','on','string',['absent'; strCh]');
        set(handles.RedChannelMenu,     'Enable','on','string',['absent'; strCh]');
        set(handles.BlueChannelMenu,    'Enable','on','string',['absent'; strCh]');
        set(handles.YellowChannelMenu,  'Enable','on','string',['absent'; strCh]');
        set(handles.RefChannelMenu,     'Enable','on','string',['absent'; strCh]');
        % enable position number, strain number and experiment description fields
        set(handles.PositionNumberBtt,      'Enable','on');
        set(handles.StrainNumberBtt,         'Enable','on');
        set(handles.ExpDescrBtt,             'Enable','on');
        % enable DeltaT field
        set(handles.DeltaTBtt,               'Enable','on');
        % enable 'set variable name' button
        set(handles.GetExistingVarFileName,  'Enable','on');
        set(handles.CreateNewVarFile,        'Enable','on');

        % enable EXTRACT DATA button
        set(handles.ExtractData,             'Enable','on');
        
        % set background color in project file panel as grey
        set(handles.ProjectFilePanel,'BackgroundColor',[0.929 0.929 0.929]);
        %
        
        % save handles and hObject
        guidata(hObject, handles);
    else
        msgbox('Ocio: non e'' mica un progetto del ciarvin!');
        % empty handles.PROJECT
        handles.PROJECT = '';
        % check: project file is not ok
        handles.check.project = 0;
        % empty text box
        set(handles.ProjectFilePath,'string','');
        % disable all the fields which need project file to be present
        %  acquisition settings: off
        set(handles.GreenChannelMenu,       'Enable','off');
        set(handles.RedChannelMenu,         'Enable','off');
        set(handles.BlueChannelMenu,        'Enable','off');
        set(handles.YellowChannelMenu,      'Enable','off');
        set(handles.RefChannelMenu,         'Enable','off');
        % disable position number, strain number and experiment description fields
        set(handles.PositionNumberBtt,      'Enable','off');
        set(handles.StrainNumberBtt,        'Enable','off');
        set(handles.ExpDescrBtt,            'Enable','off');
        %  delta t: off
        set(handles.DeltaTBtt,              'Enable','off');
        %  'set variable name' button: off
        set(handles.GetExistingVarFileName, 'Enable','off');
        set(handles.CreateNewVarFile,       'Enable','off');
        
        % set background color in project file panel as yellow
        set(handles.ProjectFilePanel,'BackgroundColor',[1 1 0]);
        % save handles and hObject
        guidata(hObject, handles);
    end
end



% --- Executes during object creation, after setting all properties.
function ProjectFileButt_CreateFcn(hObject, eventdata, handles)

function PositionNumberBtt_Callback(hObject, eventdata, handles)
% get what user wrote
PositionNumber = str2double(get(hObject,'String'));
% check if the value inserted is a number
if ~isnan(PositionNumber)
    % check if the number inserted is a valid position for the project
    if (PositionNumber > 0 && PositionNumber <= size(handles.PROJECT.pathList.position,2))
        % check if segmentation.mat is present for the given position
        if exist(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{PositionNumber},'segmentation.mat'), 'file')
            segmentation       = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{PositionNumber},'segmentation.mat'));
            % check if the position is mapped
            if isempty(nonzeros(segmentation.cells1Mapped))
                msgbox('The position you inserted has not been mapped: no data can be extracted thou.')
                % empty handles.PositionNumber
                handles.PositionNumber = '';
                % check: position number is not ok
                handles.check.position = 0;
            else
                % number of frames and ProjectName will be saved when calling EXTRACT
                
                % if it is a good position number value, save it in handles.PositionNumber
                handles.PositionNumber = PositionNumber;
                % check: position number is ok
                handles.check.position = 1;
            end
        else
            msgbox('The position you inserted has not been segmented')
            % empty handles.PositionNumber
            handles.PositionNumber = '';
            % check: position number is not ok
            handles.check.position = 0;
        end
    else
        msgbox('The position number you inserted is not present in the phylocell project indicated')
        % empty handles.PositionNumber
        handles.PositionNumber = '';
        % check: position number is not ok
        handles.check.position = 0;
    end
else
    msgbox('Position Number must be numeric!')
    % empty handles.PositionNumber
    handles.PositionNumber = '';
    % check: position number is not ok
    handles.check.position = 0;
end
guidata(hObject, handles);

function PositionNumberBtt_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% initialize position number as empty string
handles.PositionNumber = '';
guidata(hObject, handles);

% % DESCRIPTION % %
%   STRAIN
function StrainNumberBtt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% initialize strain number with an empty string
handles.StrainNumber = '';
guidata(hObject, handles);
function StrainNumberBtt_Callback(hObject, eventdata, handles)
% add the content of StrainNumberBtt as strain number (it could also be a descriptive string..)
handles.StrainNumber = get(handles.StrainNumberBtt,'string');
guidata(hObject, handles);

% EXPERIMENT
function ExpDescrBtt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.ExpDescr = '';
guidata(hObject, handles);
function ExpDescrBtt_Callback(hObject, eventdata, handles)
% add the content of StrainNumberBtt as strain number (it could also be a descriptive string..)
handles.ExpDescr= get(handles.ExpDescrBtt,'string');
guidata(hObject, handles);

% DELTAT: TIME-LAPSE BETWEEN FRAMES
function DeltaTBtt_Callback(hObject, eventdata, handles)
% get the vallue inserted by user
DeltaT = str2double(get(hObject,'String'));
if ~isnan(DeltaT)
    % save DeltaT value in handles.DeltaT
    handles.DeltaT = DeltaT;
    % check: DeltaT value is ok
    handles.check.deltat = 1;
else
    msgbox('DeltaT must be numeric!')
    % empty handles.DeltaT
    handles.DeltaT = '';
    % check: DeltaT value is not ok
    handles.check.deltat = 0;
end
guidata(hObject, handles);

function DeltaTBtt_CreateFcn(hObject, eventdata, handles)
% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
% initialize DeltaT as empty string
handles.DeltaT = '';
guidata(hObject, handles);



% % % % % % % % % % % % % % %
% % acquisition settings  % %
% % % % % % % % % % % % % % %
% --- Executes on selection change in GreenChannelMenu.
function GreenChannelMenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns GreenChannelMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GreenChannelMenu
content       = get(hObject,'String');
value         = str2double(content{get(hObject,'value')});
handles.GreenCh = value;
guidata(hObject, handles);
function GreenChannelMenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.GreenCh = NaN;
guidata(hObject, handles);


% --- Executes on selection change in RedChannelMenu.
function RedChannelMenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns RedChannelMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RedChannelMenu
content       = get(hObject,'String');
value         = str2double(content{get(hObject,'value')});
handles.RedCh = value;
guidata(hObject, handles);
function RedChannelMenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.RedCh = NaN;
guidata(hObject, handles);


% --- Executes on selection change in BlueChannelMenu.
function BlueChannelMenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns BlueChannelMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BlueChannelMenu
content       = get(hObject,'String');
value         = str2double(content{get(hObject,'value')});
handles.BlueCh = value;
guidata(hObject, handles);
function BlueChannelMenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.BlueCh = NaN;
guidata(hObject, handles);


% --- Executes on selection change in YellowChannelMenu.
function YellowChannelMenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns YellowChannelMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from YellowChannelMenu
content       = get(hObject,'String');
value         = str2double(content{get(hObject,'value')});
handles.YellowCh = value;
guidata(hObject, handles);
function YellowChannelMenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.YellowCh = NaN;
guidata(hObject, handles);


% --- Executes on selection change in RefChannelMenu.
function RefChannelMenu_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns RefChannelMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RefChannelMenu
content       = get(hObject,'String');
value         = str2double(content{get(hObject,'value')});
handles.RefCh = value;
guidata(hObject, handles);
% --- Executes during object creation, after setting all properties.
function RefChannelMenu_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
handles.RefCh = NaN;
guidata(hObject, handles);



% % % % % % % % % % % % % %
% %  ADVANCED OPTIONS   % %
% % % % % % % % % % % % % %
% initaize
function UseAdvancedOptions_CreateFcn(hObject, eventdata, handles)
handles.AdvOptions = 0;
handles.JoinMotherAndDaughter = 0;  % switch for extractdata_function and extract_fluorescence
handles.RemoveBackground      = 0;  % switch for extractdata_function and extract_fluorescence
guidata(hObject, handles);

% --- Executes on button press in UseAdvancedOptions.
function UseAdvancedOptions_Callback(hObject, eventdata, handles)
% make sub-buttons visible if Use Advanced Options is selected
handles.AdvOptions = get(hObject,'Value');


% % temporary warning
% if handles.AdvOptions
%  msgbox({'Not available, sorry!';'Only for future improvement'})
%  set(hObject,'Value',0);
%  handles.AdvOptions = 0;
% end


if handles.AdvOptions
    set(handles.JoinMotherAndDaughterCheckbox,'Enable','on')
    set(handles.RemoveBackgroundCheckbox,     'Enable','on')
else
    set(handles.JoinMotherAndDaughterCheckbox,'Enable','off')
    set(handles.RemoveBackgroundCheckbox,     'Enable','off')
end

guidata(hObject, handles);

% --- Executes on button press in JoinMotherAndDaughterCheckbox.
function JoinMotherAndDaughterCheckbox_Callback(hObject, eventdata, handles)
handles.JoinMotherAndDaughter = get(hObject,'Value');

% check if mothers are set in the selected position
segmentation = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{handles.PositionNumber},'segmentation.mat'));
if handles.JoinMotherAndDaughter && isempty(nonzeros([segmentation.tcells1(:).mother]))
    msgbox({'Mothers are not set in this position!'; 'Set mothers and try again'})
    set(hObject,'Value',0);
    handles.JoinMotherAndDaughter  = 0;
end


guidata(hObject, handles);


% --- Executes on button press in RemoveBackgroundCheckbox.
function RemoveBackgroundCheckbox_Callback(hObject, eventdata, handles)
handles.RemoveBackground = get(hObject,'Value');
guidata(hObject, handles);




% % % % % % % % % % % % % %
% % SAVE EXTRACTED DATA % %
function GetExistingVarFileName_Callback(hObject, eventdata, handles)
%VarName = strcat(handles.PROJECT.realName,'-var.mat');
VarName = strcat(handles.PROJECT.realPath,handles.PROJECT.realName,'-var.mat');
[VarName, VarPath] = uigetfile('*.mat','Join data with previously extracted ones',VarName);
% if VarPath and VarName are not 0 (they are 0 if user canceled)
if ~isequal(VarPath,0) && ~isequal(VarName,0)
    % check if the indicated file has POS and EXP in it    
    OldVar = importdata(fullfile(VarPath, VarName));
    if ~isfield(OldVar,'POS') || ~isfield(OldVar,'EXP')
        msgbox({'The indicated file does not contain POS and EXP.';'It is not an extractdata output file'});
        handles.VarName     = '';
        handles.VarPath     = '';
        handles.VarJoinFile = 0;       % this is to say: do not join an existing file
    else    
        set(handles.SaveVariablePath,'string',fullfile(VarPath, VarName));    
        handles.VarName       = VarName;
        handles.VarPath       = VarPath;
        handles.VarJoinFile   = 1;     % this is to say: join an existing file
        handles.VarCreateFile = 0;     % this is to say: do not create a new file
    end
else
    handles.VarName     = '';
    handles.VarPath     = '';
    handles.VarJoinFile = 0;       % this is to say: do not join an existing file
end

guidata(hObject, handles);

function CreateNewVarFile_Callback(hObject, eventdata, handles)
%VarName = strcat(handles.PROJECT.realName,'-var.mat');
VarName = strcat(handles.PROJECT.realPath,handles.PROJECT.realName,'-var.mat');
[VarName, VarPath] = uiputfile('*.mat','Save variables in a new file',VarName);
% if VarPath and VarName are not 0 (they are 0 if user canceled)
if ~isequal(VarPath,0) && ~isequal(VarName,0)
    set(handles.SaveVariablePath,'string',fullfile(VarPath, VarName));
    handles.VarName       = VarName;
    handles.VarPath       = VarPath;
    handles.VarJoinFile   = 0;     % this is to say: do not join an existing file
    handles.VarCreateFile = 1;     % this is to say: create a new file
else
    handles.VarName       = '';
    handles.VarPath       = '';
    handles.VarCreateFile = 0;     % this is to say: do not create a new file
end

guidata(hObject, handles);









% % % % % % % % % % % % %
% % % EXTRACT DATA!! % %
% % % % % % % % % % % % %
% --- Executes on button press in ExtractData.
function ExtractData_Callback(hObject, eventdata, handles)
global fntSize
% % check several inputs
%  position
if handles.check.position
    position_warning = 'Position number ok';
else
    position_warning = 'Position number has not been specified';
end
%  channels
channels = [handles.GreenCh, handles.RedCh, handles.BlueCh, handles.YellowCh, handles.RefCh];
% if at least one channel has been specified
if ~isempty(channels(~isnan(channels)))
    % if there are repeated channel numbers (except NaN channels, that is: absent channels)
    if length(channels(~isnan(channels))) ~= length(unique(channels(~isnan(channels))))
        channel_warning = 'Do not repeat channel numbers!';
        handles.check.channels = 0;
    else
        channel_warning = 'Channel numbers are ok';
        handles.check.channels = 1;
    end
else
    channel_warning = 'No channel number has been specified';
    handles.check.channels = 0;
end
%  deltat
if handles.check.deltat
    deltat_warning = 'Delta T is ok';
else
    deltat_warning = 'Delta T has not been correctrly specified';
end

% checks are: on channels, on position, on deltat (and on project, but the previous ones need the project to be correctly given)
if ~(handles.check.channels && handles.check.position && handles.check.deltat)
    msgbox({channel_warning; position_warning; deltat_warning});
    % if every (needed) check is ok, call the fuction actually extracting data
else
    msgbox({channel_warning; position_warning; deltat_warning;'Exctract data!'});
    
    segmentation = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{handles.PositionNumber},'segmentation.mat'));
    % save number of frames, ProjectName and channels as array
    %handles = extractdata_fillHandles(handles, segmentation);
    % first and last movie frames
    handles.FirstFrame       = 1;
    handles.LastFrame        = size(segmentation.discardImage,2);
    % first and last mapped movie frames
    handles.FirstMappedFrame = find(segmentation.cells1Mapped == 1, 1, 'first');
    handles.LastMappedFrame  = find(segmentation.cells1Mapped == 1, 1, 'last');
    % project name
    handles.ProjectName      = handles.PROJECT.realName;
    % channel numbers
    handles.channels         = [handles.GreenCh, handles.RedCh, handles.BlueCh, handles.YellowCh, handles.RefCh];
    
    
    % START EXTRACTING %
    fprintf(' Extracting data: \n');
    % initialize BKG
    BKG(1:max(handles.channels(~isnan(handles.channels)))) = struct('Mean',nan(handles.LastFrame,1),'Color','');
    % compute real background if and only if it has been asked to
    if handles.RemoveBackground
        fprintf('  Extracting background: ');
        BKG              = extractdata_background(handles);
        fprintf('\n');
    end
    [EXP, POS, CELL] = extractdata_function(handles, BKG);
    
    % save acquired data into outcome variables (expecially into POS)
    % add background data (in BKG) in position data (in POS)
    POS(handles.PositionNumber).Background   = BKG;
    % add cell data (in CELL) in position data (in POS)
    POS(handles.PositionNumber).CellData     = CELL;
    % add AllCellNumbers, an array with the numbers (the dientification numbers!) of every cell in this position
    POS(handles.PositionNumber).AllCellNumbers = [];
    for i =1:size(CELL,2)
        if isempty(CELL(i).n)
            continue
        end
        POS(handles.PositionNumber).AllCellNumbers = [POS(handles.PositionNumber).AllCellNumbers CELL(i).n];
    end
    % if destination folder and varialbe name are given, save variables
    if ~isempty(handles.VarName) && ~isempty(handles.VarPath)
        % if it is ansked to save a new file..
        if     handles.VarCreateFile
            save(fullfile(handles.VarPath,handles.VarName),'EXP', 'POS');
            % ..or itf it is asked to join an existing file
        elseif handles.VarJoinFile
            [EXP, POS, CELL] = extractdata_saveVariables(handles, EXP, POS, CELL);
        end
    end
    
    % put the outputs in varargout
    varargout{1} = EXP;
    varargout{2} = POS;
    varargout{3} = CELL;
    % success message!
    msgbox({'EXTRACTION SUCCESSFUL!';'Close extractdata figure twice to go back to your workspace'});
    
    handles.output = varargout;
    guidata(hObject,handles);
end
guidata(hObject, handles);
