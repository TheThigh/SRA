% The function of this subscript is to automatically recognize the name of
% the port currently being used.

% 2023.04.05
% This version modified some of the functions which are going to be removed
% from MATLAB library in the coming future version to increase its
% applicability.

function devices = UARTDevicesFunc()
devices = {};
coms = serialportlist();
if isempty(coms)
    return;
end
out = {};
outK = {};
cellKey = {'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\USB\'; ...
            'HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\FTDIBUS\'};

for j = 1: 2
    key = cellKey{j};
    [~, vals] = dos(['REG QUERY ' key ' /s /f "FriendlyName" /t "REG_SZ"']);
    if ischar(vals) && strcmp('ERROR',vals(1: 5))
        return;
    end
    vals = textscan(vals,'%s','delimiter','\t');
    vals = cat(1,vals{:});
    friendlyNameIndex = find(contains(vals, 'FriendlyName') == 1); 
    outValue = vals(friendlyNameIndex)';
    outKValue = vals(friendlyNameIndex - 1)';
    out(end + 1: end + length(outValue)) = outValue;
    outK(end + 1: end + length(outKValue)) = outKValue;
    if ~isempty(out)
        break;
    end
end
if isempty(out)
    return;
end

Sservices = {};
for i = 1: numel(coms)
    match = contains(out,[char(coms(i)), ')']);
    [~, sers] = dos(['REG QUERY "' outK{match == 1} '" /f "Service" /t "REG_SZ"']);
    sers = textscan(sers,'%s','delimiter','\t');
    sers = cat(1,sers{:});
    if (numel(sers)>1)
        sers=split(sers{2});
        Sservices(end + 1) = sers(3);
    end
end
saveIndex = 1;
Sservices=unique(Sservices);
for ss=1: numel(Sservices)
    key = ['HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\services\' Sservices{ss} '\Enum'];
    [~, vals] = dos(['REG QUERY ' key ' /f "Count"']);
    vals = textscan(vals,'%s','delimiter','\t');
    vals = cat(1,vals{:});
    if (numel(vals)>1)
        vals=split(vals{2});
        Count=hex2dec(vals{3}(3:end));
        if Count>0
            [~, vals] = dos(['REG QUERY ' key]);
            vals = textscan(vals,'%s','delimiter','\t');
            vals = cat(1,vals{:});
            valsIndex = contains(vals, '   REG_SZ   ');
            vals = vals(valsIndex == 1);
            for i = 1:numel(vals)
                Enums=split(vals{i});
                try 
                    nums=hex2dec(Enums{1});
                catch
                    nums=-1;
                end
                if(nums == i - 1)
                    out=['HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Enum\' Enums{3}];
                    [~, NameF] = dos(['REG QUERY "' out '" /s /f "FriendlyName" /t "REG_SZ"']);
                    NameF = textscan(NameF,'%s','delimiter','\t');
                    NameF = cat(1,NameF{:});
                    NameF = split(NameF{2}, 'REG_SZ    ');
                    NameF = NameF{end};
                    devices{saveIndex, 1} = NameF; %#ok<AGROW>1
%                    devices{i_dev,2} = com; %#ok<AGROW> Loop size is always small
                    devices{saveIndex, 2} = char(coms(saveIndex)); %#ok<AGROW> Loop size is always small.
                    saveIndex = saveIndex + 1;
                end
            end
        end
    end
end

end

%% Update Notes %%
% 2023.04.08
% The smart design part of this function is that it can automatically
% recognize all the devices currently connected to the PC by the UART
% protocol so that any other devices like U disk or our phone will not be
% in the device list as output.


