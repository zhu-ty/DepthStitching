function [loc_roi] = get_roi(xml,w_resized,h_resized)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%input xml, w = 2000, h = 1500
%normlize the roi
rect_xml = xmlread(xml);
allListitems = rect_xml.getElementsByTagName('refRect');
str = allListitems.item(0).getFirstChild.getData;
loc_roi = str2num(char(strsplit(strrep(char(str),'\n',' '))));

loc_roi = loc_roi./[w_resized;h_resized;w_resized;h_resized];
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
end