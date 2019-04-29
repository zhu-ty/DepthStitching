clc;
clear;
close all;

%define
MAX_PNG_VALUE = 60000; %same to MAXIMUM_DEPTH
MIN_PNG_VALUE = 1000; %same to MINIMUM_DEPTH

%prepare data

rect_xml = xmlread('loc1.mesh.xml');
str = rect_xml.getElementsByTagName('refRect').item(0).getFirstChild.getData;
loc_roi = str2num(char(strsplit(strrep(char(str),'\n',' '))));

%x1,x2,y1,y2
lcRoiN = [loc_roi(1) / 2000, (loc_roi(1) + loc_roi(3)) / 2000, ...
    loc_roi(2) / 1500, (loc_roi(2) + loc_roi(4)) / 1500];
refNo =  str2num(rect_xml.getElementsByTagName('refInd').item(0).getFirstChild.getData);

ref_xml = xmlread('transferdata.xml');
DISPARITY_MIN_THR = str2num(ref_xml.getElementsByTagName('DISPARITY_MIN_THR').item(0).getFirstChild.getData);
MAXIMUM_DEPTH = str2num(ref_xml.getElementsByTagName('MAXIMUM_DEPTH').item(0).getFirstChild.getData);
MINIMUM_DEPTH = str2num(ref_xml.getElementsByTagName('MINIMUM_DEPTH').item(0).getFirstChild.getData);
DEPTH_MULTIPLIER = str2num(ref_xml.getElementsByTagName('DEPTH_MULTIPLIER').item(0).getFirstChild.getData);

a = str2num(ref_xml.getElementsByTagName(['ref',num2str(refNo),'_a']).item(0).getFirstChild.getData);
b = str2num(ref_xml.getElementsByTagName(['ref',num2str(refNo),'_b']).item(0).getFirstChild.getData);
Kwidth = str2num(ref_xml.getElementsByTagName(['ref',num2str(refNo),'_Kwidth']).item(0).getFirstChild.getData);
Kheight = str2num(ref_xml.getElementsByTagName(['ref',num2str(refNo),'_Kheight']).item(0).getFirstChild.getData);
str = ref_xml.getElementsByTagName(['ref',num2str(refNo),'_Kinv']).item(0).getElementsByTagName(['data']).item(0).getFirstChild.getData;
Kinv = str2num(char(strsplit(strrep(char(str),'\n',' '))));
Kinv = reshape(Kinv,3,3)';

clear('str','rect_xml','ref_xml','loc_roi');

j_matrix = repmat([0:Kwidth-1],[Kheight,1]);
i_matrix = repmat([0:Kheight-1]',[1,Kwidth]);

j_matrix_pick = j_matrix(...
    round(lcRoiN(3) * Kheight) + 1 : round(lcRoiN(4) * Kheight) + 1,...
    round(lcRoiN(1) * Kwidth) + 1 : round(lcRoiN(2) * Kwidth) + 1);
i_matrix_pick = i_matrix(...
    round(lcRoiN(3) * Kheight) + 1 : round(lcRoiN(4) * Kheight) + 1,...
    round(lcRoiN(1) * Kwidth) + 1 : round(lcRoiN(2) * Kwidth) + 1);
writeftif(i_matrix_pick,'imatrix.tiff');
system(['ImageWarper ',...
    'imatrix.tiff',' ','loc1.mesh.xml',' ', ...
    num2str(size(i_matrix_pick,2)),' ',num2str(size(i_matrix_pick,1)),' ','warpback_imatrix', ' 1 NoNear']);
wbi = pfmread('warpback_imatrix.float.pfm');
delete('warpback_imatrix.float.pfm', 'warpback_imatrix.mask.png','imatrix.tiff');

writeftif(j_matrix_pick,'jmatrix.tiff');
system(['ImageWarper ',...
    'jmatrix.tiff',' ','loc1.mesh.xml',' ', ...
    num2str(size(j_matrix_pick,2)),' ',num2str(size(j_matrix_pick,1)),' ','warpback_jmatrix', ' 1 NoNear']);
wbj = pfmread('warpback_jmatrix.float.pfm');
delete('warpback_jmatrix.float.pfm', 'warpback_jmatrix.mask.png','jmatrix.tiff');

%input disparity: same size as local, interesting area with non-zero
D = double(abs(imread('sample.tiff')));
wbi = imresize(wbi, size(D));
wbj = imresize(wbj, size(D));
lenMap = zeros(size(D));
for i = 1:size(D,1)
    for j = 1:size(D,2)
        if(D(i,j) == 0)
            continue;
        end
        d1 = D(i,j) * a + b;
        if(d1 < DISPARITY_MIN_THR)
            lenMap(i,j) = MAXIMUM_DEPTH;
            continue;
        end
        d3 = (1 / d1) * DEPTH_MULTIPLIER;
        xyz = Kinv * [d3 * wbj(i,j);d3 * wbi(i,j);d3];
        len = norm(xyz);
        if(len > MAXIMUM_DEPTH)
            lenMap(i,j) = MAXIMUM_DEPTH;
        elseif(len < MINIMUM_DEPTH)
            lenMap(i,j) = MINIMUM_DEPTH;
        else
            lenMap(i,j) = len;
        end
    end
end

%Generate PNG File
% pngValue = (len - baseD) * KKDP + baseP;
OptPng = uint16(zeros(size(lenMap)));
KKDP = (MAX_PNG_VALUE - MIN_PNG_VALUE) / (MAXIMUM_DEPTH - MINIMUM_DEPTH);
baseD = MINIMUM_DEPTH;
baseP = MIN_PNG_VALUE;
for i = 1:size(D,1)
    for j = 1:size(D,2)
        if(lenMap(i,j) >= MINIMUM_DEPTH) % not zero
            OptPng(i,j) = (lenMap(i,j) - baseD) * KKDP + baseP;
        end
    end
end
imwrite(OptPng, 'lenMap_loc1_frameXX.png');