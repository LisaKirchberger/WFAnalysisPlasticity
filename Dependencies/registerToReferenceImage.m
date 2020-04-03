function registerToReferenceImage(Image, refImage, savepath, AnalysisParameters)

%% load in TM 
load(fullfile(savepath, 'AligningResults.mat'), 'TM')


%% plot the pre, post Alignment 

F = figure('name',savepath, 'Position', [548 510 1237 539], 'visible', AnalysisParameters.PlotFigures);

subplot(1,2,1)
ima = (single(refImage) - min(single(refImage(:))))./(max(single(refImage(:)))-min(single(refImage(:))));
imb = (single(Image) - min(single(Image(:))))./(max(single(Image(:)))-min(single(Image(:))));
imagesc(imfuse(histeq(ima),histeq(imb)))
axis square
title('Before')

subplot(1,2,2)
regImage = imwarp(Image,TM,'OutputView',imref2d(size(refImage)));
imc = (single(regImage) - min(single(regImage(:))))./(max(single(regImage(:)))-min(single(regImage(:))));
h = imagesc(imfuse(histeq(ima),histeq(imc)));
axis square
title('After')

%% manually improve the overlay?

F1 = figure('Position', [519 57 1134 1048]);
regImage =  imwarp(Image,TM,'OutputView',imref2d(size(refImage)));
imc = (single(regImage) - min(single(regImage(:))))./(max(single(regImage(:)))-min(single(regImage(:))));
imagesc(imfuse(histeq(ima),histeq(imc)));

% ask if want to improve overlay --> looked at many and actually overlay
% was always really goood, so got rid of it
%improveOverlay = questdlg('Do you want to improve the overlay?','Shift more','yes','no','no');
improveOverlay = 'no';


if strcmp(improveOverlay,'yes')
    
    title('a = left, d = right, s = down, w = up, f/g = xscale down/up, r/t yscale down/up, v/b rotation down/up, k for okay, q reset')
    okay = 0;
    key = '0';
    
    while ~okay
        if strcmp(key,'d')
            TM.T(3,1)=TM.T(3,1)+1;
            key = '0';
        elseif strcmp(key,'a')
            TM.T(3,1)=TM.T(3,1)-1;
            key = '0';
        elseif strcmp(key,'w')
            TM.T(3,2) = TM.T(3,2)-1;
            key = '0';
        elseif strcmp(key,'s')
            TM.T(3,2) = TM.T(3,2)+1;
            key = '0';
        elseif strcmp(key,'g')
            TM.T(1,1) = TM.T(1,1)*1.05;
            key = '0';
        elseif strcmp(key,'f')
            TM.T(1,1) = TM.T(1,1)/1.05;
            key = '0';
        elseif strcmp(key,'r')
            TM.T(2,2) = TM.T(2,2)/1.05;
            key = '0';
        elseif strcmp(key,'t')
            TM.T(2,2) = TM.T(2,2)*1.05;
            key = '0';
        elseif strcmp(key,'v')
            TM.T(1,2) = TM.T(1,2)/1.05;
            TM.T(2,1) = TM.T(2,1)/1.05;
            key = '0';
        elseif strcmp(key,'b')
            TM.T(1,2) = TM.T(1,2)*1.05;
            TM.T(2,1) = TM.T(2,1)*1.05;
            key = '0';
        elseif strcmp(key,'k')
            okay = 1;
        elseif strcmp(key,'q')
            [optimizer, metric] = imregconfig('multimodal');
            TM = imregtform(Image,refImage,'similarity',optimizer,metric);
            key = '0';
        else
            waitforbuttonpress
            key = get(gcf,'CurrentCharacter');
        end
        
        figure(F1)
        regImage =  imwarp(Image,TM,'OutputView',imref2d(size(refImage)));
        imc = (single(regImage) - min(single(regImage(:))))./(max(single(regImage(:)))-min(single(regImage(:))));
        imagesc(imfuse(histeq(ima),histeq(imc)));
        axis square
        title('a = left, d = right, s = down, w = up, f/g = xscale down/up, r/t yscale down/up, v/b rotation down/up, k for okay, q for reset')
        
    end
end
close(F1)


%% update the Figure with the refined overlay

figure(F)
subplot(1,2,2)
regImage =  imwarp(Image,TM,'OutputView',imref2d(size(refImage)));
imc = (single(regImage) - min(single(regImage(:))))./(max(single(regImage(:)))-min(single(regImage(:))));
h = imagesc(imfuse(histeq(ima),histeq(imc)));
axis square
title('After')


%% save
saveas(F, fullfile(savepath,'RegistrationOverlay.fig'));
saveas(F, fullfile(savepath,'RegistrationOverlay.bmp'));
save(fullfile(savepath, 'AligningResults.mat'), 'TM');


end