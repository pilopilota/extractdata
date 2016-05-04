%
% 
% IMPORTANT! to use this you need a divisionTime in  the daughter cell to mark the end of the mother/daughter couple
%  if daughter cell has no divisionTime, it will be analyszed together with the mother until the end of exp (this is to preserve triplets, if any)
%
% so: first divisionTime of a cell A (aparto from cells present in the first frame of the movie) is the one identifying the end of mother/daughter couple
%  the second divisionTime is the one marking the division between cell A and its daughter, and so on

coppie  = struct('All',[]);
COUPLES = struct('frame',cell(1));
MOTHERS = struct('frame',cell(1));


fprintf('  find cells groups (mother and daughters) for each frame\n');

segmentation = importdata(fullfile(handles.PROJECT.realPath,handles.PROJECT.pathList.position{p},'segmentation.mat'));

coppie(p).All = [];
for c = 1:length(segmentation.tcells1)
    if ~segmentation.tcells1(c).N, continue; end
    DDD   = segmentation.tcells1(c).N;
    MMM   = segmentation.tcells1(c).mother;
    if MMM == DDD, MMM = 0; end
    fBorn = max([segmentation.tcells1(c).detectionFrame,1]);
    if ~isempty(segmentation.tcells1(c).divisionTimes) && MMM
        % I mark as division frame the minimum frame between mother's and daughter's division time which is AFTER the frame marking the beginning of the couple
        fDiv  = sort([segmentation.tcells1(c).divisionTimes, segmentation.tcells1(segmentation.tcells1(c).mother).divisionTimes]);
        fDiv  = fDiv(find(fDiv > fBorn,1,'first'));
    else
        fDiv = NaN;
    end
    
    % some useful checks for triplets
    if length(segmentation.tcells1(c).divisionTimes) ~= length(segmentation.tcells1(c).daughterList)
        fprintf('   warning: number of divison times ~= number of daughters \t (cell %d) \n',segmentation.tcells1(c).N)
    end
    % se 3 frames prima o dopo la divisione della figlia la madre non ha una divisione forse il bud della figlia e' in realta' un bud della madre
    %  per cui la coppia va controllata
    
fprintf(' Pos:\t%d\tCell:\t%d\n',p,c);


    if ~isempty(segmentation.tcells1(c).divisionTimes) && MMM && fBorn ~= 1 && ...
            min(abs(segmentation.tcells1(MMM).divisionTimes - min(segmentation.tcells1(c).divisionTimes))) > 2
        fprintf('   warning: cell %d has a daughter, but probably it is %d daughter \n',DDD,MMM);
    end
    
    % save in 'coppie': only cells present at first frame can have no mother. others must have (Lavoisier)
    if MMM == 0 && fBorn == 1, coppie(p).All = [coppie(p).All; fBorn DDD 0   fDiv];    % this is for the first cells..
    else                       coppie(p).All = [coppie(p).All; fBorn MMM DDD fDiv];    % ...this for all the others
    end
end
%
% sort 'coppie' on birth frame
if ~isempty(coppie(p).All),
    [F, iX] = sort(coppie(p).All(:,1));
    coppie(p).All(:,1) = F;
    coppie(p).All(:,2) = coppie(p).All(iX,2);
    coppie(p).All(:,3) = coppie(p).All(iX,3);
    coppie(p).All(:,4) = coppie(p).All(iX,4);
end
% check orphans
Orphans = find(coppie(p).All(:,2) == 0);
if ~isempty(Orphans)
%    Orphans = Orphans(find(coppie(p).All(Orphans,1) > POS(p).FirstMappedFrame));
    Orphans = Orphans(find(coppie(p).All(Orphans,1) > 1));
end
if ~isempty(Orphans)
    Orphans = coppie(p).All(Orphans,3);
    fprintf('   These cells are orphans: find their mother! \n');
    fprintf('    %d\n',Orphans);
end



% % create COUPLES and MOTHERS % %
% now: I build groups of cell bodies: for each frame I want a cell list, grouping together mother and daughter(s) at that frame
for f = POS(p).FirstFrame:POS(p).LastFrame
    MOTHERS.frame{f} = [];
    COUPLES.frame{f} = [];
    % find raws corresponding to cells born NOT AFTER f
    b_first = find(coppie(p).All(:,1) <= f,1,'first');
    b_last  = find(coppie(p).All(:,1) <= f,1,'last');
    % find mothers for frame f (frame 1 is different)
    if f == 1
        % mothers at first frame are all the cells, even the ones with no daughters
        MOTHERS.frame{f} = [unique(coppie(p).All(b_first:b_last,2))]';
    else
        % for other frames: these are candidate mothers
        temp = unique(coppie(p).All(b_first:b_last,2:3));
        temp = [nonzeros(temp)]';
        % candidates are actually mothers if and only if
        %  they are not daughters of a couple existing at frame f
        % in this way I exclude cells appearing only once, in daughter list in 'coppie', and has divisionFrame after f or equal to NaN (meaning no division)
        for M = temp
            [RowM, ColM] = find(coppie(p).All(b_first:b_last,2:3) == M);
            RowM = RowM + b_first - 1;
            ColM = ColM + 2       - 1;
            if length(ColM) == 1 && ColM(1) == 3 && (coppie(p).All(RowM,4) > f || isnan(coppie(p).All(RowM,4))), continue; end
            MOTHERS.frame{f} = [MOTHERS.frame{f}, M];
        end
    end
    %
    % now for each mother in MOTHERS I group her daughters, per frame: one, two or more daugthers at time
    for M = MOTHERS.frame{f}
        IndexM = find(coppie(p).All(b_first:b_last,2) == M);
        % se sono effettivamente madri, cerco le coppie di cui hanno fatto parte: quelle gi? concluse non le considero, le altre son tutte presenti
        if ~isempty(IndexM)
            Daughters = coppie(p).All(IndexM + b_first - 1, :);
            Daughters = Daughters([find(Daughters(:,4) > f)', find(isnan(Daughters(:,4)))'],3);     % ci sono sia le coppie che termineranno DOPO f, sia quelle che non termineranno (NaN)
            Daughters = [nonzeros(Daughters)]';
            % altrimenti significa che sono delle figlie che si sono separate dalla madre, quindi stanno da sole
        else
            Daughters = [];
        end
        COUPLES.frame{f} = [ COUPLES.frame{f} zeros(size(COUPLES.frame{f},1), length([M Daughters]) - size(COUPLES.frame{f},2))  ; M Daughters zeros(1,size(COUPLES.frame{f},2) - length([M Daughters]))];
    end
end
