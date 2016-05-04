
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% THIS IS WHAT YOU HAVE TO EDIT %
% % WHAT TO PLOT
PositionNumber  = 2;             % position:                for the three plots
ChannelNumber   = 2;             % channel number:          for the three plots
Measure         = 'Mean';        % fluorescence measure:    for the three plots
CellNumber      = 3;             % cell number:             for the first plot
CellList        = [3, 5, 7];     % cell numbers list:       for the third plot




% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % % %
% YO DON'T NEED TO EDIT HERE, BUT TAKE A LOOK %

variable = open('extractdata_plot_try_VAR.mat');

EXP = variable.EXP;
POS = variable.POS;
clear variable

% figure settings
lnWidthProva = 1.8;
fntSizeProva = 14;

% FIRST PLOT: only the indicated cell
figure()
plot(EXP.Time, POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).(Measure), 'Color',POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).Color, 'LineWidth', lnWidthProva)
xlabel(EXP.TimeUnits, 'FontSize', fntSizeProva);
ylabel('arbitrary units', 'FontSize', fntSizeProva);
title({[Measure,' of ', POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).Color, '-tagged protein'];...
    ['Cell number ',num2str(CellNumber)]; ...
    ['Background removal: ',POS(PositionNumber).RemoveBackground];...
    ['Join mother and daughter: ',POS(PositionNumber).JoinMotherAndDaughter]...
    }, 'FontSize', fntSizeProva);


% SECOND PLOT: all the cells in the indicated position
figure()
hold on
MAP = colormap('jet');
for iCell = 1:size(POS(PositionNumber).AllCellNumbers,2)
    CellNumber = POS(PositionNumber).AllCellNumbers(iCell);
    iColor = mod(iCell*3,size(colormap,1));
    plot(EXP.Time, POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).(Measure), 'Color',MAP(iColor,:),'LineWidth', lnWidthProva/5)
end
xlabel(EXP.TimeUnits, 'FontSize', fntSizeProva);
ylabel('arbitrary units', 'FontSize', fntSizeProva);
title({[Measure,': ', POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).Color, '-tagged protein'];...
    ['All cells in position ',num2str(PositionNumber)]; ...
    ['Background removal: ',POS(PositionNumber).RemoveBackground];...
    ['Join mother and daughter: ',POS(PositionNumber).JoinMotherAndDaughter]...
    }, 'FontSize', fntSizeProva);


% THIRD PLOT: only cells in the indicated cell list
figure()
hold on
MAP = colormap('jet');
for iCell = 1:size(CellList,2)
    CellNumber = CellList(iCell);
    iColor = mod(iCell*3,size(colormap,1));
    plot(EXP.Time, POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).(Measure), 'Color',MAP(iColor,:),'LineWidth', lnWidthProva/5)
end
xlabel(EXP.TimeUnits, 'FontSize', fntSizeProva);
ylabel('arbitrary units', 'FontSize', fntSizeProva);
title({[Measure,': ', POS(PositionNumber).CellData(CellNumber).FluoData(ChannelNumber).Color, '-tagged protein'];...
    ['Background removal: ',POS(PositionNumber).RemoveBackground];...
    ['Join mother and daughter: ',POS(PositionNumber).JoinMotherAndDaughter]...
    }, 'FontSize', fntSizeProva);
