function [disGlobalRsel, disLocalRSel, maskRSel,stGxyRSel,select,maskR,disLocalR,stGxyR]=pre_PIE(vy_global, mixsize,loc_roi,warpedMasksLocal,warpedVxLocal,vx_local)
stGxyR = [round(loc_roi(1) * mixsize(2)), round(loc_roi(2) * mixsize(1))];%放大后对应的ROI的起点
%this function should be used before PIE(image preprocessing)
%input global_disparity mixsize(size of fianl global_disp) roi
%warpedMasksLocal,warpedVxLocal local_disparity
%output disGlobalRsel, disLocalRSel, maskRSel is useful for PIE
%other output is for debugging, ignore it
hL = size(vx_local,1);
wL = size(vx_local,2);
disGlobalR = vy_global;%resize
warpedVxLocal(warpedVxLocal < 0) = 0;
warpedMasksLocal = uint8(zeros(size(warpedVxLocal)));
warpedMasksLocal(warpedVxLocal > 0) = 255;

maskR = uint8(zeros(mixsize));%mask
maskR(stGxyR(2) : (stGxyR(2) + size(warpedMasksLocal, 1) - 1),...
    stGxyR(1) : (stGxyR(1) + size(warpedMasksLocal, 2) - 1)) = ...
    warpedMasksLocal;
disLocalR = double(zeros(mixsize));%放入warped后的local
disLocalR(stGxyR(2) : (stGxyR(2) + size(warpedMasksLocal, 1) - 1),...
    stGxyR(1) : (stGxyR(1) + size(warpedMasksLocal, 2) - 1)) = ...
    warpedVxLocal;
select = round(size(warpedMasksLocal) .* 1.4);%选取1.4倍区域
stGxyRSel = stGxyR - round([wL,hL] .* 0.2);%调整起点

disGlobalRsel = disGlobalR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2));
disLocalRSel = disLocalR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2));
maskRSel = maskR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
maskRSel = imerode(maskRSel, ones(9));

end