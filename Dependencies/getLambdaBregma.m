function [LambdaMouse,BregmaMouse,AllXshift,AllYshift,XScale,YScale,shiftX,shiftY,Model] = getLambdaBregma(referenceimage,Model,notstopped)

if nargin<3
    notstopped = 1;
end

if ~notstopped
    LambdaMouse = NaN;
    BregmaMouse = NaN;
    scale = 0;
else

f = figure; imagesc((referenceimage));colormap gray;axis square

hold on
%Get Bregma and Lambda information
disp('Choose First Bregma & then Lambda location, doubleclick for last position...')
title('Choose First Bregma & then Lambda location, doubleclick for last position...')
scale = 1;
end

while notstopped
    
    if exist('hh','var')
        delete(hh)
    end
    [x,y] = getline(f);
    
    BregmaMouse = [x(1) y(1)];
    LambdaMouse = [x(2) y(2)];
    
    hh(1) = plot(BregmaMouse(1),BregmaMouse(2),'r*','MarkerSize',25);
    hold on
    hh(2) = text(BregmaMouse(1),BregmaMouse(2),'Bregma');
    
    hh(3) = plot(LambdaMouse(1),LambdaMouse(2),'b*','MarkerSize',25);
    hold on
    hh(4) = text(LambdaMouse(1),LambdaMouse(2),'Lambda');
    button = questdlg('Lambda/Bregma okay?','LambdaBregmaSelection', 'OK','try again','OK');
    if strcmp(button,'OK')
        notstopped = 0;
    end
    
end

xpixnew = size(referenceimage,1);
ypixnew = size(referenceimage,2);
xpixold = size(Model.WholeCortex,2);
ypixold = size(Model.WholeCortex,1);

XImageScale = xpixnew/xpixold;
YImageScale = ypixnew/ypixold;

Model.Lambda(1) = Model.Lambda(1)*XImageScale;
Model.Lambda(2) = Model.Lambda(2)*YImageScale;
Model.Bregma(1) = Model.Bregma(1)*XImageScale;
Model.Bregma(2) = Model.Bregma(2)*YImageScale;
Model.AllX = Model.AllX*XImageScale;
Model.AllY = Model.AllY*YImageScale;
for i = 1:length(Model.Boundaries)
    for j = 1:length(Model.Boundaries{i})
        Model.Boundaries{i}{j}(:,1)=  Model.Boundaries{i}{j}(:,1)*XImageScale;
        Model.Boundaries{i}{j}(:,2)=  Model.Boundaries{i}{j}(:,2)*YImageScale;
    end
end

% Scaling
if scale
    XScale = (Model.Lambda(1) - Model.Bregma(1))/(LambdaMouse(1)-BregmaMouse(1));
    YScale = (Model.Lambda(2) - Model.Bregma(2))/(LambdaMouse(2)-BregmaMouse(2));
    if YScale ==0
        YScale = 1;
    end
else
    %IF JUST USING ALLEN
    XScale = 1;
    YScale = 1;
end


AllX_sc=Model.AllX/XScale;
AllY_sc=Model.AllY/YScale;

if scale
% shift Averaged
shiftX = (Model.Bregma(1)/XScale - BregmaMouse(1));
shiftY =  (Model.Bregma(2)/YScale -  BregmaMouse(2));
else
shiftX = 0;
shiftY = 0;
end

% Apply shift
AllXshift = AllX_sc-shiftX;
AllYshift = AllY_sc-shiftY;

ind_800=find(AllXshift>xpixnew);
AllXshift(ind_800)=[];
AllYshift(ind_800)=[];


figure;
imshow(histeq(referenceimage))
hold on
h = scatter(AllXshift,AllYshift,'k.');