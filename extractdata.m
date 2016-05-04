function [EXP, POS, CELL] = extractdata(handles)
% GOAL
%  in a user friendly manner, this script will return some key features of cells in a specific position of a phylocell project
% INPUT
% if no input is given, a GUI will open and you can stop reading all the following list.
% otherwise, the input must be a structure containing the following fields (these MUST be the names):
%  - fields that can NOT be left empty:
%    'AdvOptions'       : 1 or 0, to ask for advanced options. now, it must be 0
%    'PositionNumber'   : the position number. it must be a number, of course.
%    'RefCh'            : the reference channel as phylocell calls it. if absent, give NaN as value (RefCh = NaN)
%    'BlueCh'           : the blue channel as phylocell calls it. if absent, give NaN as value 
%    'YellowCh'         : the yellow channel as phylocell calls it. if absent, give NaN as value
%    'RedCh'            : the red channel as phylocell calls it. if absent, give NaN as value
%    'GreenCh'          : the green channel as phylocell calls it. if absent, give NaN as value
%    'DeltaT'           : the 
%    'PROJECT'          : the project file (not its name: the file itself) as phylocell creates it
%
%  -fields that can be left empty (but MUST be present)
%    'strain'           : a description of the strain for the given position, or a number. can be empty (that is: '')
%    'ExpDescr'         : and experiment description (this will be the figure caption, so do not write a book). can be empty 
%    'VarName'          : the name you want for the output variables to be saved (can be empty)
%    'VarPath'          : the folder where you want to output to be saved (can be empty)
%    'TimeUnits'        : a string with the time units you want. usually 'min'. (can be empty)
%
%  -fields for future implementation
%    'MediumList'       : to be implemented later
%    'AddMediumChange'  : to be implemented later    
    







% check for phylocell folder in the path
% phylocell functions MUST be in the MATLAB path, otherwise segmentation would not be open correctly
%  (this is because some of the segmentation fields are phy_objects, that is a class of MATLAB object defined by charvin & friends:
%  without the phy_object definition files, segmentation will be half-empty)
if ~exist('phy_Object.m','file')
 h = msgbox({'Warning!';'Add phylocell folder to the MATLAB path!';'(e.g: addpath(''./phyloCellv1.8/phylocell'')'});
 return;
end


% if no input arguments are given, call the GUI
if nargin == 0
    [EXP, POS, CELL] = extractdata_GUI;
% otherwise, go on in a 'scripting' way
else
    
 % substitute the path as saved in the PROJECT file with the real ones
 %  (there could be problems since phylocell only saves paths when the project is created: 
 %   if project file has been moved or folder name has changed, no way to know it. 
 %   phylocell uses the same
 
 
 
 

 % build up the following fields using the given info
 %    'ProjectName'      : the name of the project, that is the suffix for all the images folders and files 
 %    'channels'         : the channel number used, all together (NaNs can be or not present, is the same. no specific order is required)
 %    'FirstFrame'       : the first frame of the movie, in number. usually 1
 %    'LastFrame'        : the last frame of the movie, in number
 %    'FirstMappedFrame' : the first mapped frame of the movie, in number (can be found as find(segmentation.cells1Mapped == 1, 1, 'first'))
 %    'LastMappedFrame'  : the last mapped frame of the movie, in number  (can be found as find(segmentation.cells1Mapped == 1, 1, 'last')
 segmentation = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{handles.PositionNumber},'segmentation.mat'));
 handles      = extractdata_fillHandles(handles, segmentation);
 
    
    

    
 fprintf('bene!\n')
 EXP  = 0;
 POS  = 0;
 CELL = 0;
%  [EXP, POS, CELL] = extractdata_function(handles);
%  BKG              = extractdata_background(handles);
%  % add background data (in BKG) in position data (in POS)
%  POS(handles.PositionNumber).Background   = BKG;
%  % add cell data (in CELL) in position data (in POS)
%  POS(handles.PositionNumber).CellData     = CELL;

% %  % if destination folder and varialbe name are given, save variables
%  if ~isempty(handles.VarName) && ~isempty(handles.VarPath)
%   % save variables and eventually join existing and new variables for the same experiment 
%   %  (if they have the same name, they will be joined!)
%   [EXP, POS, CELL ] = extractdata_savevariables(handles, EXP, POS, CELL);
%  end


end