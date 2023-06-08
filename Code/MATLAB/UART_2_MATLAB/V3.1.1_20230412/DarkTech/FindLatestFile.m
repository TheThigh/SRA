% 2023.04.07
% This function is to find the lastest file created by system or MATLAB
% code originally (not been fixed), and the information stored in the
% system struct will help us to finish the electronics' serial data
% communication set up if we are using exacly the same PC (organisor) as
% last time (we can compare the MAC address in another function to identify
% it).

function temp=FindLatestFile(temp)

FileFolder=fullfile([temp.mfile.path,'\Results']);
file=dir(fullfile(FileFolder,'*.mat'));
filelist={file.name}';
[r,~]=size(filelist);
temp.matfile.list=filelist;
if r~=0
    for i=1:r
        temp.matfile.list{i,2}=temp.matfile.list{i,1};
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'.mat','');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Jan','01');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Feb','02');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Mar','03');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Apr','04');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'May','05');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Jun','06');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Jul','07');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Aug','08');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Sep','09');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Oct','10');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Nov','11');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'Dec','12');
        temp.matfile.name.digit=temp.matfile.list{i,2};
        temp.matfile.name.dash_pos=strfind(temp.matfile.name.digit,'_');
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},temp.matfile.name.digit(1:temp.matfile.name.dash_pos(1)),'');
        temp.matfile.name.digit=temp.matfile.list{i,2};
        temp.matfile.name.dash_pos=strfind(temp.matfile.name.digit,'_');
        temp.matfile.name.year=temp.matfile.name.digit(temp.matfile.name.dash_pos(2)+1:temp.matfile.name.dash_pos(3)-1);
        temp.matfile.name.month=temp.matfile.name.digit(temp.matfile.name.dash_pos(1)+1:temp.matfile.name.dash_pos(2)-1);
        temp.matfile.name.day=temp.matfile.name.digit(1:temp.matfile.name.dash_pos(1)-1);
        temp.matfile.list{i,2}=[temp.matfile.name.year,temp.matfile.name.month,temp.matfile.name.day,...
            temp.matfile.name.digit(temp.matfile.name.dash_pos(3)+1:end)];
        temp.matfile.list{i,2}=replace(temp.matfile.list{i,2},'_','');
    end
    temp.matfile.name.simp={};
    for i=1:r
        temp.matfile.name.simp=[temp.matfile.name.simp;temp.matfile.list{i,2}];
    end
    temp.matfile.name.sequence=sortrows(temp.matfile.name.simp);
    temp.matfile.target.digit=temp.matfile.name.sequence(end);
    for i=1:r
        if ~isempty(strfind(temp.matfile.list{i,2},temp.matfile.target.digit))
            temp.matfile.target.pos=i;
            temp.matfile.target.name=temp.matfile.list{i,1};
        end
    end

else
    temp.devices=[];

end


