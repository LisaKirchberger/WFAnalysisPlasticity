figure;imagesc(Fergon);colormap gray;hold on; plot(Model.AllX,Model.AllY,'k.','Markersize',0.2);axis square, box off, axis off;plot(Model.Bregma(1), Model.Bregma(2), 'w*')
MMperPix = 0.0276;
PixperMM = 36.2631;
[x,y]=ginput(2);
PPC = [x(1)+PixperMM*2 y(1)+PixperMM*1.7];
V1 = [x(2)-PixperMM*1 y(2)+PixperMM*2.7];
plot(PPC(1), PPC(2),'r*')
plot(V1(1), V1(2), 'b*')