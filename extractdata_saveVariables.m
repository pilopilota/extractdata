function [EXP, POS, CELL] = extractdata_saveVariables(handles, EXP, POS, CELL)
% this function join together variables from the same experiment
% and save them where user said.


FullVarName = fullfile(handles.VarPath, handles.VarName);
% since his is for already existing variables, it updates POS by joining it with new variables
if exist(FullVarName,'file')
    OldVar = importdata(FullVarName);
    % check: do old and new variables have the same fields?
    PosFields = fieldnames(POS);
    for iField = 1:numel(PosFields)
        field = PosFields{iField};
        if ~isfield(OldVar.POS, field)
            msgbox({'Old POS variable does not have the same fields as the new one'; [field, ' is missing']});
            break
        end
    end
    ExpFields = fieldnames(EXP);
    for iField = 1:numel(ExpFields)
        field = ExpFields{iField};
        % compare string variables
        if ischar(OldVar.EXP.(field))
            if ~strcmp(OldVar.EXP.(field), EXP.(field))
                msgbox({'Old EXP variable is not the same as the new one'; [field, ' is different']});
            end 
        % compare non-string variables
        elseif ~(OldVar.EXP.(field) == EXP.(field))
            if ~(isnan(OldVar.EXP.(field)) && isnan(EXP.(field)))
                msgbox({'Old EXP variable is not the same as the new one'; [field, ' is different']});
                break
            end
        end
    end
    
    % join new POS with the new one
    for PosNum = 1:size(OldVar.POS,2)
        if PosNum ~= handles.PositionNumber
            POS(PosNum)           = OldVar.POS(PosNum);
        end
    end
end
% save updated variables
save(FullVarName,'EXP', 'POS');



