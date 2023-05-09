function [dev] = rad_read_acs_devfile(devfilename)
%.. desiderio 24-aug-2015
%.. read in calcoeffs from the input WETLabs tab-delimited acs dev file  
%.. into the output structure dev.
%
%.. devfilename must include the full path of the devfile unless
%.. the file is located in the working directory.

%.. 14-sep-2015 revision:
%..    corrected the dev.ctbin and dev.atbin assignment statements;
%..    original release hardcoded 85 for nwvl and 35 for ntbin.
clear C D

fid = fopen(devfilename);
%.. read in 1st 10 lines.
C = textscan(fid, '%s', 10, 'whitespace', '', 'delimiter', '\n');
%.. get rid of wrapping cell array
C = C{1};

%.. parse into dev data structure
dev.sernum = sscanf(['0x' C{2}(3:8)], '%i');  % instrument serial number
%.. be careful with the date; my first attempt at reading this line
%.. worked in 99% of the cases, but there was some funny business with
%.. one of the dev files. Rather than kluging a fix, try a more general
%.. approach.

[dev.tcal, dev.ical, dev.date] = parse_devfile_offset_save_row(C{4});
%.. dev.tcal = cal water temperature 
%.. dev.ical = internal instrument temperature during cal
%.. dev.date = date that offsets were saved to the dev file

dev.depcal = sscanf(C{5}, '%f')';     % depth cal coeff [offset slope]
dev.pathlength = sscanf(C{7}, '%f');  % optical path length [m]
dev.nwvl = sscanf(C{8}, '%u');    % number of wavelengths
dev.ntbin = sscanf(C{9}, '%u');   % number of internal temperature correction bins
dev.tbin = sscanf(C{10}, '%f')';  % bin temperature values

%.. read in wavelength-specific cal variables.
fff = repmat('%f', 1, dev.ntbin);  % t correction format field
E = textscan(fid, ...
    ['%s %s %*s %f %f %*f' fff '%*f' fff '%*[^\n]'], ...
    dev.nwvl, 'delimiter', '\t');
fclose(fid);

%.. parse
dev.cwvl = str2double(strrep(E{1},'C','0'));  % beam c wavelengths
dev.awvl = str2double(strrep(E{2},'A','0'));  % absorption wavelengths
dev.coff = E{3};                  % beam c purewater offsets
dev.aoff = E{4};                  % absorption purewater offsets

%.. 14-sep-2015 correction - use dev.nwvl and dev.ntbin
array = cell2mat(E(5:end));
dev.ctbin = array(1:dev.nwvl, 1:dev.ntbin);
dev.atbin = array(1:dev.nwvl, dev.ntbin+1:2*dev.ntbin);

% clear C,D,E
end

function [Tcal, Ical, date] = parse_devfile_offset_save_row(str)

str = strrep(str, ',', '.');
idxC = strfind(upper(str), 'C.');
if numel(idxC)~=2
    error('Could not parse acs devfile dateline');
end
    
idxa = strfind(lower(str), 'tcal:');
idxb = idxC(1);
if isempty(idxa) || isempty(idxb)
    error('Could not parse Tcal acs devfile value.');
end
Tcal = sscanf(str(idxa+5:idxb-1), '%f');
%
idxa = strfind(lower(str), 'ical:');
idxb = idxC(2);
if isempty(idxa) || isempty(idxb)
    error('Could not parse Ical acs devfile value.');
end
Ical = sscanf(str(idxa+5:idxb-1), '%f');
%
disp(' ');
disp(['Tcal and Ical are:  ', num2str([Tcal Ical])]);

idx = strfind(str, '/');
if length(idx) ~= 2
    error('Could not parse ''offset save'' date in devfile.')
end
month = sscanf(str( idx(1)-2 : idx(1)-1), '%u');
day   = sscanf(str( idx(1)+1 : idx(2)-1), '%u');
%.. year might be yy, might be yyyy, might have a period after it.
%.. might have a ".
year = sscanf(str( idx(2)+1 : end), '%s');
year = strtrim(strrep(year, '.', ''));
year = strtrim(strrep(year, '"', ''));
year = year(end-1:end);

date = ['20' year '-' num2str(month,'%2.2u') '-' num2str(day,'%2.2u')];
disp(['Devfile date that offsets were saved:  ', date]);
disp(' ');

end
