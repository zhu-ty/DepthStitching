%one global disparity one local disparity
%input global_disp.tiff local_disp.tiff loc.mesh.xml sky_mask.png(optional)
%output global disparity with one local disparity
%the final output is vy_global
clear;
%load('center_global.mat')
xml = 'loc1.mesh.xml';
disp = imread('ref_405.tiff');
%disp = imcrop(disp,[0,0,896,500]);
vy_global = imread('global_background_fine.tiff');
mask = imread('1d.png');%sky_mask
%keep in mind the local disparity should be padded!
pad = double(ones(672,900));
pad = -999.*pad;
pad(1:size(disp,1),1:size(disp,2)) = disp;
vx_local = pad;
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

w_resized = 2000;%resize后的图片大小
h_resized = 1500;

loc_roi = get_roi(xml,w_resized,h_resized);

[k,mixsize,~,~]=get_k_size(vy_global,vx_local,loc_roi,disp);
vx_local_fix = vx_local ./k;%k
writeftif(vx_local_fix, 'local_vx_origin.tiff');

[warpedVxLocal, warpedMasksLocal] = warping('local_vx_origin.tiff',xml,vx_local,'warped_local_dis.tiff');
vy_global = imresize(vy_global,mixsize);
[disGlobalRsel, disLocalRSel, maskRSel,stGxyRSel,select,maskR,disp,stGxyR]=pre_PIE(vy_global, mixsize,loc_roi,warpedMasksLocal,warpedVxLocal,vx_local);
result = PIE(disGlobalRsel, disLocalRSel, maskRSel, 0 , 1);
origin = vy_global(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2)); %without local disparity

vy_global(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2)) = result;%final result 
test_result = vy_global(stGxyR(2) : stGxyR(2) + size(warpedMasksLocal, 1) - 1,stGxyR(1) : stGxyR(1) + size(warpedMasksLocal, 2) - 1); %the current local area disparity

%result = vy_global;
% figure(1),imshow(result,[]);
% figure(2),imshow(origin,[]);
% figure(3),imshow(test_result,[]);

%writeftif(vy_global,'vy_global.tiff');
%system('rm *.pfm');