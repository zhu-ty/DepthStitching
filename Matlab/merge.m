clear;
load('raw_data.mat');
hG = size(imGlobal,1);
wG = size(imGlobal,2);
hL = size(imLocal,1);
wL = size(imLocal,2);

imGROI = imGlobal(...
    round(loc_roi(2) * hG) : round((loc_roi(2) + loc_roi(4)) *hG),...
    round(loc_roi(1) * wG) : round((loc_roi(1) + loc_roi(3)) *wG), :);
vyGROI = vy_global(...
    round(loc_roi(2) * hG) : round((loc_roi(2) + loc_roi(4)) *hG),...
    round(loc_roi(1) * wG) : round((loc_roi(1) + loc_roi(3)) *wG));
GloRoiMean = mean(mean(vyGROI));
LocMean = mean(mean(vx_local));
vx_local_fix = vx_local ./ (LocMean / GloRoiMean);

writeftif(vx_local_fix, 'local_vx_origin.tiff');
system(['ImageWarper Texture.vertexshader.glsl Texture.fragmentshader.glsl ',...
    'local_vx_origin.tiff loc0.mesh.yml ', ...
    num2str(wL),' ',num2str(hL),' warped_local_dis.tiff']);
warpedVxLocal = pfmread('warped_local_dis.tiff.float.pfm');
warpedMasksLocal = imread('warped_local_dis.tiff.mask.png');

mixsize = round(size(vy_global) .* (hL / size(imGROI,1)));
stGxyR = [round(loc_roi(1) * mixsize(2)), round(loc_roi(2) * mixsize(1))];

%test color mix
imGlobalR = imresize(imGlobal, mixsize);
immaskR = uint8(zeros(mixsize));
immaskR(stGxyR(2) : (stGxyR(2) + size(warpedMasksLocal, 1) - 1),...
    stGxyR(1) : (stGxyR(1) + size(warpedMasksLocal, 2) - 1)) = ...
    warpedMasksLocal;
imLocalR = uint8(zeros([mixsize,3]));
imLocalR(stGxyR(2) : (stGxyR(2) + size(warpedMasksLocal, 1) - 1),...
    stGxyR(1) : (stGxyR(1) + size(warpedMasksLocal, 2) - 1), :) = ...
    imLocal;
%test = PIE(imGlobalR, imLocalR, maskR, 0 , 0);
select = round(size(warpedMasksLocal) .* 1.4);
stGxyRSel = stGxyR - round([wL,hL] .* 0.2);

imGlobalRsel = imGlobalR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2), :);
imLocalRSel = imLocalR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2), :);
immaskRSel = immaskR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2), :);
% test = PIE(imGlobalRsel, imLocalRSel, immaskRSel, 0 , 0);
immaskRSel = imerode(immaskRSel, ones(9));

disGlobalR = imresize(vy_global, mixsize);
maskR = uint8(zeros(mixsize));
maskR(stGxyR(2) : (stGxyR(2) + size(warpedMasksLocal, 1) - 1),...
    stGxyR(1) : (stGxyR(1) + size(warpedMasksLocal, 2) - 1)) = ...
    warpedMasksLocal;
disLocalR = uint8(zeros([mixsize,3]));
disLocalR(stGxyR(2) : (stGxyR(2) + size(warpedMasksLocal, 1) - 1),...
    stGxyR(1) : (stGxyR(1) + size(warpedMasksLocal, 2) - 1)) = ...
    warpedVxLocal;
% test = PIE(imGlobalR, imLocalR, maskR, 0 , 0);
select = round(size(warpedMasksLocal) .* 1.4);
stGxyRSel = stGxyR - round([wL,hL] .* 0.2);

disGlobalRsel = disGlobalR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2));
disLocalRSel = disLocalR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2));
maskRSel = maskR(stGxyRSel(2) : stGxyRSel(2) + select(1),...
    stGxyRSel(1) : stGxyRSel(1) + select(2));
maskRSel = imerode(maskRSel, ones(9));

test = PIE(disGlobalRsel, disLocalRSel, maskRSel, 1 , 1);
imshow(warpedVxLocal,[]);
figure(3);
imshow(disGlobalRsel,[]);
figure(2);
imshow(test,[]);