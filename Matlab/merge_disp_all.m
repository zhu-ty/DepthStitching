%one global disparity, n local disparity(in this case n = 2)
%input local.mesh.xml*n global_disp.tiff local_disp.tiff*n
%output global disparity with n local disparity
%this version ignore the local mask
clear;
num = 2;
w_resized = 2000;%resize后的图片大小
h_resized = 1500;
xml = {'./loc1.mesh.xml','loc2.mesh.xml'};
vy_global = imread('global_pwc.tiff');
disp1 = imread('local_disp.tiff');
disp2 = imread('reff_68.tiff');
disp = {disp1,disp2};

pad = double(ones(672,900));
pad = -999.*pad;

for i = 1:num
    vx_local(:,:,i) = pad;
    vx_local(1:size(disp{i},1),1:size(disp{i},2),i) = disp{i};
    loc_roi(i,:) = get_roi(xml{i},w_resized,h_resized);
    [k(i),mixsize(i,:),ratio(i),ratio2(i)]=get_k_size(vy_global,vx_local(:,:,i),loc_roi(i,:),disp{i});
end
% [y,ind] = max(mixsize(:,1)); 
% mixsize_max = mixsize(ind,:)
% rate = mixsize_max(1,1) ./ mixsize(:,1)
[r_max,ind] = max(ratio);
mixsize_max = mixsize(ind,:);
rate1 = r_max ./ ratio;
rate2 = ratio2(ind) ./ ratio2;
vy_global = imresize(vy_global,mixsize_max);
for j = 1:num
    vy_global = mergedisp(vy_global,vx_local(:,:,j),xml{j},loc_roi(j,:),mixsize_max,k(j),rate1(j),rate2(j));
end