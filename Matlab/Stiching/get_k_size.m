function [k,mixsize,ratio,ratio2] = get_k_size(vy_global,vx_local,loc_roi,disp)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%input:global disp;local disp;loc_roi(normallized)
%output1 k(make the value of local disparity consist with global disparity)
%output2 mixsize(the size of final global disparity)
%output3 ratio(global h 需要扩大倍数)
%output4 ratio2(global w 需要扩大倍数)
hG = size(vy_global,1);
wG = size(vy_global,2);
hL = size(vx_local,1);
wL = size(vx_local,2);
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
vyGROI = vy_global(...
    round(loc_roi(2) * hG) : round((loc_roi(2) + loc_roi(4)) *hG),...
    round(loc_roi(1) * wG) : round((loc_roi(1) + loc_roi(3)) *wG));
GloRoiMean = mean(mean(vyGROI));

LocMean = mean(mean(disp));
k = LocMean / GloRoiMean;%k
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
ratio = hL / size(vyGROI,1);
ratio2 = wL / size(vyGROI,2);

mixsize = [round(size(vy_global,1) .* ratio),round(size(vy_global,2).*ratio2)];

end