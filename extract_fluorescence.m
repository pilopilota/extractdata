function FluoData = extract_fluorescence(handles, segmentation, ChNumber, COUPLES, BKG)
% this function returns a struct which fields are the fluorescence data for the given position
%  (as segmentation and handles.PositionNumber indicete) and for the given channel number (ChNumber).
% this function is called by extractdata_function

% interface parameters
verbose = 0;
SaveImgs    = 0;    % it takes a loooooooooooot of time to do it!

% localization index parameters
PrcTile = 99;



p = handles.PositionNumber;
% set in which folder images are
imgsPath   = fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.channels{p,ChNumber});
% initialize FluoData, the output. FluoData is indexed on cell number
FieldList = {'Mean','Min','Max','Sum','LocInd'};
EmptyStruct = struct();
for iField = 1:numel(FieldList)
    EmptyStruct.(FieldList{iField}) = nan(handles.LastFrame,1);
end
EmptyStruct.RawData = cell(handles.LastFrame,1);
FluoData(1:max(unique(nonzeros([segmentation.cells1.n])))) = EmptyStruct;

% for every frame in the movie (both the ones mapped and not)
for f = handles.FirstFrame:handles.LastFrame
    if ~mod(f,5), fprintf('*'); end  % print a sort of waiting bar
    % open the right image (project, position, channel, frame)
    F = imread(fullfile(imgsPath,strcat(handles.PROJECT.pathList.names{handles.PositionNumber,ChNumber},'-',num2str(f,'%03.f'),'.jpg')));
    
    % if asked to, subtract background in nonzeros pixels (in this way black images are kept black, and skipped)
    if handles.RemoveBackground
        % increase non-zeros values which are below the background for this channel and frame to the value of the background
        F(F~=0 & F<BKG(ChNumber).Mean(f)) = BKG(ChNumber).Mean(f);
        F = F - uint16((F ~=0)*BKG(ChNumber).Mean(f));
    end
    
    %
    % get the data
    % what if user asks for advanced options?
    %  look in 130823/NucDivision.m for having an idea of it
    % for every cell in the movie, numbered as user sees it in phylocell
    %  ('nonzeros' is to exclude cells saved with number 0, that are sort of errors. unique is to avoid repetitions)
    for NCell = unique(nonzeros([segmentation.cells1.n]))'
        % tell me where you are
        if verbose
            fprintf('  cell: %d \t frame: %d \n',NCell, f);
        end
        % skip non-mapped frames and black images
        if (f < handles.FirstMappedFrame || f > handles.LastMappedFrame) || isempty(nonzeros(F))
            continue;
        end
        
        % set nCell as the index corresponding to NCell in frame f, that is: segmentation.cells1(f,nCell).n = NCell
        %  (in this way, only cells presen at frame f (already birth and not death) can be included
        nCell = 0;
        i = 1;
        while ~nCell && i<=numel(segmentation.cells1(f,:))
            if NCell == segmentation.cells1(f,i).n
                nCell = i;
            end
            i = i+1;
        end
        % if a cell is not present in this frame (nCell = 0), skip this cell for this frame
        if ~nCell
            continue
        end
        
        % % build cell's mask (mask) % %
        if verbose, fprintf('   cell: %d \n',NCell); end
        % build mother's mask (maskM)
        MBirth = max([segmentation.tcells1(NCell).detectionFrame, 1]);
        ageM   = f - MBirth + 1;
        xCellM = segmentation.tcells1(NCell).Obj(ageM).x;      yCellM = segmentation.tcells1(NCell).Obj(ageM).y;
        xM     = segmentation.tcells1(NCell).Obj(ageM).ox;     yM     = segmentation.tcells1(NCell).Obj(ageM).oy;
        maskM  = poly2mask(xCellM,yCellM,size(F,1),size(F,2));
        % initialize limits for zooming on the image
        XMINM  = min(xCellM);   YMINM = min(yCellM);
        XMAXM  = max(xCellM);   YMAXM = max(yCellM);
        % initialize daughter cell limits 
        %  (in case no mother-daughter junction is required they'll be NaNs)
        XMIND  = NaN;           YMIND = NaN;
        XMAXD  = NaN;           YMAXD = NaN;
        
        % if asked to join mother and daughter
        if handles.JoinMotherAndDaughter
            % skip if NCell is not present at frame f (that can be: COUPLES do not record death)
            if segmentation.tcells1(NCell).lastFrame < f, continue; end
            % skip if NCell is a Daughter (it is not present in the first column of COUPLES at frame f)
            if ~sum(COUPLES.frame{f}(:,1) == NCell),      continue; end
            % Daughter is cell's daughters' number list
            Daughters = COUPLES.frame{f}(COUPLES.frame{f}(:,1) == NCell,2:end);    Daughters = [nonzeros(sort(Daughters))]';
            % initialize masks:
            % 'mask' will be the complete mask: mother and daughter(s) together
            % 'maskD'  will be the daughters' masks (all together)
            % 'maskJ'  will be the mask with all the joints together
            mask   = maskM;
            maskD  = zeros(size(F));
            maskJ  = maskD;
                        
            % find the daughter(s), if any and add their mask(s) to the mother's one
            for DDD = Daughters
                if ~DDD, continue; end
                % skip if DDD is not present at frame f (that can be: COUPLES do not record death)
                if segmentation.tcells1(DDD).lastFrame < f, continue; end
                
                DBirth = max([segmentation.tcells1(DDD).detectionFrame, 1]);
                ageD = f - DBirth + 1;
                
                xCellD = segmentation.tcells1(DDD).Obj(ageD).x;      yCellD = segmentation.tcells1(DDD).Obj(ageD).y;
                XMIND  = min([XMIND; xCellD(:)]);                    YMIND  = min([YMIND; yCellD(:)]);
                XMAXD  = max([XMAXD; xCellD(:)]);                    YMAXD  = max([YMAXD; yCellD(:)]);
                
                xD     = segmentation.tcells1(DDD).Obj(ageD).ox;     yD     = segmentation.tcells1(DDD).Obj(ageD).oy;
                % add the two masks
                par = linspace(0,1,100);
                xr  = (1-par).*xM+par.*xD;                  yr  = (1-par).*yM+par.*yD;
                w_per = [yM-yD; xD-xM];
                % Setting gam value (shift from the line r) for the bandwith
                gam   = 0.13;
                xrUP  = xr+gam*w_per(1);    yrUP = yr+gam*w_per(2);
                xrDW  = xr-gam*w_per(1);    yrDW = yr-gam*w_per(2);
                X     = [xrUP xrDW];        Y    = [yrUP yrDW];         conv = convhull(X,Y);
                X     = X(conv);            Y    = Y(conv);
                
                %Selecting mother and daughter from the image + the intermediate region between them
                maskD  = or(maskD, poly2mask(xCellD,yCellD,size(F,1),size(F,2)));
                maskJ  = or(maskJ, poly2mask(X,Y,size(F,1),size(F,2)));
                mask   = or(or(mask,maskD),maskJ);
            end
        % if it is not asked to join mother and daughter
        else
            % Selecting cell from the image
            mask  = maskM;
        end
        % take data as double
        mask  = double(immultiply(uint16(mask),F));
        
        % zooming on the image
        XMIN  = min([XMINM,XMIND]);                 YMIN   = min([YMINM, YMIND]);
        WIDTH = (max([XMAXM, XMAXD]))- XMIN;        HEIGHT = (max([YMAXM,YMAXD]))-YMIN;
        RECT  = [XMIN YMIN WIDTH HEIGHT];
        mask  = imcrop(mask,RECT);
        
        if SaveImgs
            FigActualImg = figure();
            imshow(mask,[min(nonzeros(mask)), max(nonzeros(mask))]);
            if SaveImgs
                if handles.JoinMotherAndDaughter
                    MaD = '_MothAndDaugh';
                else
                    MaD = '_SingleCell';
                end
                if handles.RemoveBackground
                    RmBkg = '_RemoveBKG';
                else
                    RmBkg = '_NoBKGRemoval';
                end
                FileName = strcat('ExtractFluo',MaD,RmBkg,'_pos',num2str(p),'_cell',num2str(NCell),'_f',num2str(f),'.eps');
                saveas(FigActualImg,fullfile(handles.PROJECT.realPath,'imgs',FileName),'psc2');
                close(FigActualImg)
            end
        end
        % get data
        
        %QUI VA MESSO UN CONTROLLO SUGLI ELEMENTI DI FieldList: AGGIORNO SOLO QUELLI PRESENTI
        FluoData(NCell).Mean(f) = mean(nonzeros(mask));
        FluoData(NCell).Min(f)  = min(nonzeros(mask));
        FluoData(NCell).Max(f)  = max(nonzeros(mask));
        FluoData(NCell).Sum(f)  = sum(nonzeros(mask));
        % localization index
        PRC      = prctile(nonzeros(mask),PrcTile);
        meanPRC  = mean(mask(mask >= PRC));
        meanALL  = mean(nonzeros(mask));
        STDall   = std(nonzeros(mask));
        FluoData(NCell).LocInd(f) = (meanPRC - meanALL)/STDall; %(mean(mask(mask >= prctile(nonzeros(mask),PrcTile))) - mean(nonzeros(mask)))/std(nonzeros(mask));
        
        % raw data
        FluoData(NCell).RawData{f} = mask;
        
    end
end




% color names %

% add 'Color' field in FluoData, according to the names in handles
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
% put the right Color in every FluoData cell
for NCell = 1:size(FluoData,2)
    FluoData(NCell).Color = Color;
end