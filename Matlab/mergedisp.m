function [vy_global]=mergedisp(vy_global,vx_local,xml,loc_roi,mixsize,k,rate1,rate2)
%function mergedisp
%input: global_disparity,local_disp,xml,loc_roi(normed),mixsize(resize
%global),k(local_mean./global_mean)),rate1(local_h./roi_h),rate2(local_w./roi_w)

%output:vy_global stitched with vx_local
vx_local_fix = vx_local ./k;%k
writeftif(vx_local_fix, 'local_vx_origin.tiff');

[warpedVxLocal, warpedMasksLocal] = warping('local_vx_origin.tiff',xml,vx_local,'warped_local_dis.tiff');

warpedVxLocal = imresize(warpedVxLocal,[size(vx_local,1)*rate1,size(vx_local,2)*rate2],'nearest');
warpedMasksLocal = imresize(warpedMasksLocal,[size(vx_local,1)*rate1,size(vx_local,2)*rate2],'nearest');

[disGlobalRsel, disLocalRSel, maskRSel,stGxyRSel,select,~,~,~]=pre_PIE(vy_global, mixsize,loc_roi,warpedMasksLocal,warpedVxLocal,vx_local);

result = PIE(disGlobalRsel, disLocalRSel, maskRSel, 0 , 1);
vy_global(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2)) = result; 

end