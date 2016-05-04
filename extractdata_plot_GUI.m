function varargout = extractdata_plot_GUI(varargin)

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @extractdata_plot_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @extractdata_plot_GUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
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


% % % % % % % % % % 
% OPEN the FIGURE %
% % % % % % % % % % 
% --- Executes just before extractdata_plot_GUI is made visible.
function extractdata_plot_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to extractdata_plot_GUI (see VARARGIN)

% Choose default command line output for extractdata_plot_GUI
handles.output = hObject;

% initialize some handles fields
handles.PositionNumber    = [];
handles.PlotCellsTogether = 0;

% initializa verbose
verbose = 0;


% % % % % % % % % % % % % % % % % % % % % % % 
% USE THE INPUTS TO SET SOME INITIAL VALUES %
if nargin<5
 msgbox({'This function needs two inputs:'; ' - a variable with experiment details';' - a variable with cells data for at least one position'})
 msgbox({'close this image and call again the function with the right imput arguments'});
 % find a way to close the image
else
 if verbose 
  fprintf('nargin: %d \n', nargin) 
 end
 handles.EXP = varargin{1};
 handles.POS = varargin{2};

 % initialize handles.check: it count how many of the basic fields are correctly filled (from 0 to 4):
 %  experimental details
 %  position number
 %  cell to plot number
 %  frames to plot
 handles.check = 0;
 
 % initialize position, cells and frames detail
 handles.PositionNumber = '';
 handles.FirstFrame     = '';
 handles.LastFrame      = '';
 handles.CellList       = '';
 
 % initialize values about fluorescence plot
 handles.GreenObject  = '';     handles.GreenNoBkg  = 0;
 handles.RedObject    = '';     handles.RedNoBkg    = 0;
 handles.BlueObject   = '';     handles.BlueNoBkg   = 0;
 handles.YellowObject = '';     handles.YellowNoBkg = 0;
 
 % initialize values about non-fluorescence plot
 handles.PlotArea     = 0;
 handles.PlotBudding  = 0;
 handles.PlotDivision = 0;
 
 % initialize 'save' details
 handles.ImagesFolder = '';
 
 
 % EXPERIMENT FILE PATH in the upper text slot
 set(handles.ExpFileText,'String',handles.EXP.ProjectFullFile);
 handles.check = handles.check + 1;
 % POSITIONS: set the ones present in POS as the only possible
 Positions    = cell(1);
 Positions{1} = '';
 j = 2;
 for i = 1:size(handles.POS,2)
  if ~isempty(handles.POS(i).Number)
   Positions{j} = i;
   j = j+1;
  end
 end
 set(handles.PositionMenu, 'String',Positions)
 % FRAMES:    set all as default
 handles.FirstFrame = 1;
 handles.LastFrame  = handles.EXP.NumberOfFrames;
 handles.Frames     = [handles.FirstFrame:handles.LastFrame];
 set(handles.FramesNumberBtt,'string',strcat(num2str(handles.FirstFrame),'-',num2str(handles.LastFrame)));
 handles.check = handles.check + 1;
end



% Update handles structure
guidata(hObject, handles);

% UIWAIT makes extractdata_plot_GUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% no output 
function varargout = extractdata_plot_GUI_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;



% --- Executes during object creation, after setting all properties.
function ExpFileText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ExpFileText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called


% % % % % % % 
% POSITION  %
% % % % % % % 
% --- Executes on selection change in PositionMenu.
function PositionMenu_Callback(hObject, eventdata, handles)
%disable cell field (it will be enabled if a non-empty position is inserted)
set(handles.CellNumberBtt,'Enable','off');
% get the position number
content                = cellstr(get(hObject,'String'));
handles.PositionNumber = str2num(content{get(hObject,'Value')});
if ~isempty(handles.PositionNumber)
 % enable the cell fiesld
 set(handles.CellNumberBtt,'Enable','on');
 
 % activate the channels
 %  enable only the ones present in this position and set in the menus the correct list (first value is empty)


 % cambia! deve essere una non vuota!!
 nCell = 1;




 % for every number in FluoData:
 for i = 1:size(handles.POS(handles.PositionNumber).CellData(nCell).FluoData,2)
  % choose the right color corresponding to FluoData(i)
  Color = handles.POS(handles.PositionNumber).CellData(nCell).FluoData(i).Color;
  % if it is Ref channel, skip it
  if     strcmp(Color, 'Ref') || isempty(Color)
   continue
  % if not, put in List the GUI menu and in NoBkg the GUI button corresponding to the color
  else
   List  = handles.(strcat(Color,'FluoList'));
   NoBkg = handles.(strcat(Color,'NoBkgBtt'));
  end
  % enable both List and NoBkg
  set(List, 'Enable','on');
  set(NoBkg,'Enable','on');
  % List is a pulldown menu: set FluoData fields as the only possible choices for what to plot
  temp = fieldnames(handles.POS(handles.PositionNumber).CellData(nCell).FluoData);
  FluoThings = cell(1);
  FluoThings{1} = '';
  jFluo = 2;
  for j = 1:numel(temp)
   % add to FluoThings all the fields in FluoData that are not 'Color'
   if ~strcmpi(temp{j},'Color')
    FluoThings{jFluo} = temp{j};
    jFluo = jFluo + 1;
   end
  end
  set(List,'string',FluoThings);
 end
end

% check: if every basic data is correctly inserted set the background panel color to grey, else to yellow
if ~isempty(get(handles.ExpFileText,'String')) && ...
   ~isempty(handles.PositionNumber)            && ...
   ~isempty(handles.Frames)                    && ...
   ~isempty(handles.CellList)
 set(handles.CellDetailsPanel, 'BackgroundColor', [240 240 240]/255);
else
 set(handles.CellDetailsPanel, 'BackgroundColor', [1 1 0]);
end
% update handles
guidata(hObject, handles);

function PositionMenu_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% % % % % 
% CELLS % 
% % % % % 
function CellNumberBtt_Callback(hObject, eventdata, handles)
% Hints: get(hObject,'String') returns contents of CellNumberBtt as text
%        str2double(get(hObject,'String')) returns contents of CellNumberBtt as a double
CellList = get(hObject,'String');
if ~isempty(CellList)
 % get the list of values as an array of numbers
 handles.CellList = str2arr(CellList);
 
 
 
 
 % aggiungi i controllli: le cellule devono esistere nella posizione indicata

 
 
else
 handles.CellList = [];
end

% check: if every basic data is correctly inserted set the background panel color to grey, else to yellow
if ~isempty(get(handles.ExpFileText,'String')) && ...
   ~isempty(handles.PositionNumber)            && ...
   ~isempty(handles.Frames)                    && ...
   ~isempty(handles.CellList)
 set(handles.CellDetailsPanel, 'BackgroundColor', [240 240 240]/255);
else
 set(handles.CellDetailsPanel, 'BackgroundColor', [1 1 0]);
end
guidata(hObject, handles);

function CellNumberBtt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function CellsTogetherBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of CellsTogetherBtt
handles.PlotCellsTogether = get(hObject, 'Value');
guidata(hObject, handles);



% % % % % %
% FRAMES  %
% % % % % % 
function FramesNumberBtt_Callback(hObject, eventdata, handles)
% get the value inserted by the user 
FrameNumber = get(hObject,'String');
% if is not empty
if ~isempty(FrameNumber)
 % if user wrote 'all', get all the frames
 if strcmpi(strtrim(FrameNumber),'all')
  handles.Frames = [handles.FirstFrame:handles.LastFrame];
  set(hObject,'string',strcat(num2str(handles.FirstFrame),'-',num2str(handles.LastFrame)));
 % otherwise get the interval user asked for
 else
  handles.Frames = str2arr(FrameNumber);
  if handles.Frames(1) < handles.FirstFrame || handles.Frames(end) > handles.LastFrame
   handles.Frames = [];
   set(hObject,'string','');
   msgbox({'Interval ot of bounds: ';['this movie can be analyzed between frame ',num2str(handles.FirstFrame),' and ',num2str(handles.LastFrame)]})
  end
 end
else
 handles.Frames = [];
end
% check: if every basic data is correctly inserted set the background panel color to grey, else to yellow
if ~isempty(get(handles.ExpFileText,'String')) && ...
   ~isempty(handles.PositionNumber)            && ...
   ~isempty(handles.Frames)                    && ...
   ~isempty(handles.CellList)
 set(handles.CellDetailsPanel, 'BackgroundColor', [240 240 240]/255);
else
 set(handles.CellDetailsPanel, 'BackgroundColor', [1 1 0]);
end
guidata(hObject, handles);

function FramesNumberBtt_CreateFcn(hObject, eventdata, handles)
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% % % % % % % % % % % % % 
% FLUORESCENCE SETTINGS % 
% % % % % % % % % % % % % 
% GREEN
function GreenFluoList_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns GreenFluoList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from GreenFluoList
content = cellstr(get(hObject,'String'));
handles.GreenObject = content{get(hObject,'Value')};
guidata(hObject, handles);

function GreenFluoList_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function GreenNoBkgBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of GreenNoBkgBtt
handles.GreenNoBkg = get(hObject,'Value');
guidata(hObject, handles);


% RED
function RedFluoList_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns RedFluoList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from RedFluoList
content = cellstr(get(hObject,'String'));
handles.RedObject = content{get(hObject,'Value')};
guidata(hObject, handles);

function RedFluoList_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function RedNoBkgBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of RedNoBkgBtt
handles.RedNoBkg = get(hObject,'Value');
guidata(hObject, handles);


% BLUE
function BlueFluoList_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns BlueFluoList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from BlueFluoList
content = cellstr(get(hObject,'String'));
handles.BlueObject = content{get(hObject,'Value')};
guidata(hObject, handles);

function BlueFluoList_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function BlueNoBkgBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of BlueNoBkgBtt
handles.BlueNoBkg = get(hObject,'Value');
guidata(hObject, handles);


% YELLOW
function YellowFluoList_Callback(hObject, eventdata, handles)
% Hints: contents = cellstr(get(hObject,'String')) returns YellowFluoList contents as cell array
%        contents{get(hObject,'Value')} returns selected item from YellowFluoList
content = cellstr(get(hObject,'String'));
handles.YellowObject = content{get(hObject,'Value')};
guidata(hObject, handles);

function YellowFluoList_CreateFcn(hObject, eventdata, handles)
% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function YellowNoBkgBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of YellowNoBkgBtt
handles.YellowNoBkg = get(hObject,'Value');
guidata(hObject, handles);



% % % % % % % % % % % % 
% OTHER non-FLUO DATA % 
% % % % % % % % % % % % 
% --- Executes on button press in PlotAreaBtt.
function PlotAreaBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of PlotAreaBtt
handles.PlotArea = get(hObject,'Value');
guidata(hObject, handles);

% --- Executes on button press in PlotBuddingBtt.
function PlotBuddingBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of PlotBuddingBtt
handles.PlotBudding = get(hObject,'Value');
guidata(hObject, handles);

% --- Executes on button press in PlotDivisionBtt.
function PlotDivisionBtt_Callback(hObject, eventdata, handles)
% Hint: get(hObject,'Value') returns toggle state of PlotDivisionBtt
handles.PlotDivision = get(hObject,'Value');
guidata(hObject, handles);


% % % % % 
% PLOT! %
% % % % % 
% --- Executes on button press in PlotBtt.
function PlotBtt_Callback(hObject, eventdata, handles)



% % % % % % % % 
% SAVE IMAGES % 
% % % % % % % % 
% --- Executes on button press in ChangeFolderName.
function ChangeFolderName_Callback(hObject, eventdata, handles)
% save into handles
handles.ImagesFolder = uigetdir(handles.EXP.ProjectFullPath,'Select the folder where images will be saved..');
if handles.ImagesFolder
 % write down the final part of the path
 slash = find(handles.ImagesFolder=='/');
 SubPath = handles.ImagesFolder(slash(end-2):end);
 set(handles.SaveImagesPath,'string',strcat('....',SubPath));
 % enable the save button
 set(handles.SaveBtt,'Enable','on');
end
guidata(hObject, handles);

function CancelImagesPath_Callback(hObject, eventdata, handles)
handles.ImagesFolder = '';
% disable the save button
set(handles.SaveBtt,'Enable','off');
guidata(hObject, handles);

% --- Executes on button press in SaveBtt.
function SaveBtt_Callback(hObject, eventdata, handles)
% hObject    handle to SaveBtt (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

















% --- Executes during object creation, after setting all properties.
function CellDetailsPanel_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CellDetailsPanel (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called
