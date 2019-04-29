function [warpedVxLocal,warpedMasksLocal] = warping(tiff,xml,vx_local,outname)
%warping function
%input local_disp.tiff(scaled),xml,vx_local,name(intermediate product name)
%output warpedVxLocal,warpedMasksLocal
hL = size(vx_local,1);
wL = size(vx_local,2);
system(['ImageWarper ',...
    tiff,' ',xml,' ', ...
    num2str(wL),' ',num2str(hL),' ',outname, ' 0']);
warpedVxLocal = pfmread([outname,'.float.pfm']);
size(warpedVxLocal)
warpedMasksLocal = imread([outname,'.mask.png']);
end