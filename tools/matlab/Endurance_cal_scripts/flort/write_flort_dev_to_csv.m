function csvfilename = write_flort_dev_to_csv(dev)
%.. desiderio 19-apr-2017
%.. desiderio 18-oct-2017 removed 'BBFL2W-' from serial numbers 
%..                       in 1st column of calfile.
%.. desiderio 28-nov-2017 seriesJ serial numbers WILL use 'BBFL2W-'

%*****************************************************************
%      USE THIS PROGRAM IN PREFERENCE TO write_flort_qct_to_csv 
%*****************************************************************
%
%.. reads in a FLORT (ECO BBFL2W) dev file and writes out the 
%.. calibration coefficients to an OOI GitHub cal file.

%.. dev file  BBFL2W-1030.DEV
%
% ECO BBFL2W-1030				
% Created on: 12/06/16				
% 				
% 				
% Columns=9				
% N/U=1				
% N/U=2				
% N/U=3 				
% Lambda=4	3.437E-06	48	700	700
% N/U=5   				
% Chl=6   	0.0116	 	47			
% N/U=7   				
% CDOM=8		0.0650		47	
% N/U=9				

clear C

% cd R:
% cd ..

seriesD = [ 995  996 1121 1123   1151 1152 1153 1154  ...
           1155 1197 1290 1291   1302 1303 1487 1488]; 
seriesJ = [1084 1156 1206 1207   1518 1519];

seriesK = [1030 1032 1602];  % McLane profilers CE09OSPM

caldate_provenance = 'date in filename comes from dev file';

%.. the coefficient called 'angular resolution' *isn't* 
bug = ['Erroneously named constant; this coefficient scales the ' ...
    'particulate scattering at 124 degrees to total backscatter ' ...
    'from particles'];

%.. channels:
%   (1) backscatter at 700nm
%   (2) chl fluorescence
%   (3) cdom fluorescence
channel  = {'lambda' 'chl' 'cdom'};

fid = fopen(dev);
%.. read in all lines. seems as if there may be some variation in the use
%.. of spaces and tabs, so:
C = textscan(fid, '%s%s%s%s%s', 'delimiter', {' ', '\t'}, ...
    'MultipleDelimsAsOne', 1);
fclose(fid);
%.. C is a 1x5 cell array of strings:
%..     column 1 has the sensor identifier strings 
%..     column 2 has the scale coeffs
%..     column 3 has the caldate and dark counts

%.. parse serial number from first line of devfile
%.. .. some files have 'BBFL2W-', some have 'BBFL2-'
idx = find(~cellfun(@isempty, strfind(C{2},'BBFL2W-')), 1);
if ~isempty(idx)
    idx_ch = strfind(C{2}{idx}, 'BBFL2W-');
    sernum = str2double(C{2}{idx}(idx_ch+7:end));
else
    idx = find(~cellfun(@isempty, strfind(C{2},'BBFL2-')), 1);
    if ~isempty(idx)
        idx_ch = strfind(C{2}{idx}, 'BBFL2-');
        sernum = str2double(C{2}{idx}(idx_ch+6:end));
    else
        error('Cannot parse serial number from within infile');
    end
end


%.. find series based on serial number
if ismember(sernum, seriesD)
    series = 'D';
elseif ismember(sernum, seriesJ)
    series = 'J';
elseif ismember(sernum, seriesK)
    series = 'K';
else
    disp(sernum);
    error('FLORT Series cannot be determined from serial number.');
end

%.. now convert serial number to 5 characters
sn_str = num2str(sernum, '%5.5u');

%.. find date of cal
idx = find(~cellfun(@isempty, strfind(lower(C{1}),'created')), 1);
calstring = C{3}{idx};  % generalize read for permutations of m/d/yy
D = textscan(calstring,'%u%c%u%c%u');
yyyy = num2str(D{5}, '%4.4u');
yyyy(1) = '2';  % should be good for some years.
mm = num2str(D{1}, '%2.2u');
dd = num2str(D{3}, '%2.2u');
caldate = [yyyy mm dd];

%.. parse for dark counts and scale factor values
darkcounts  = {'','',''};
scalefactor = {'','',''};
for ii=1:3
    idx = find(~cellfun(@isempty, strfind(lower(C{1}), channel{ii})), 1);
    scalefactor(ii) = C{2}(idx);
    darkcounts{ii} = C{3}{idx}; 
end

%.. construct output filename
csvfilename = ['CGINS-FLORT' series '-' sn_str '__' caldate '.csv'];

%.. construct serial number string to be into column 1 of calfile
if strcmpi(series, 'J')
    sn_str = ['BBFL2W-' num2str(sernum)];
else
    sn_str = num2str(sernum);
end

%.. write directly out to a text file, no xlsx in-between.
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\r\n', header);

fprintf(fid, '%s,%s,%s,%s\r\n', ...
    sn_str, 'CC_dark_counts_cdom', darkcounts{3}, caldate_provenance);
fprintf(fid, '%s,%s,%s,\r\n', ...
    sn_str, 'CC_scale_factor_cdom', scalefactor{3});
fprintf(fid, '%s,%s,%s,\r\n', ...
    sn_str, 'CC_dark_counts_chlorophyll_a', darkcounts{2});
fprintf(fid, '%s,%s,%s,\r\n', ...
    sn_str, 'CC_scale_factor_chlorophyll_a', scalefactor{2});
fprintf(fid, '%s,%s,%s,\r\n', ...
    sn_str, 'CC_dark_counts_volume_scatter', darkcounts{1});
fprintf(fid, '%s,%s,%s,\r\n', ...
    sn_str, 'CC_scale_factor_volume_scatter', scalefactor{1});
fprintf(fid, '%s,%s,%s,%s\r\n', ...
    sn_str, 'CC_depolarization_ratio', '0.039', 'Constant');
fprintf(fid, '%s,%s,%s,%s\r\n', ...
    sn_str, 'CC_measurement_wavelength', '700', '[nm]; Constant');
fprintf(fid, '%s,%s,%s,%s\r\n', ...
    sn_str, 'CC_scattering_angle', '124', '[degrees]; Constant');
fprintf(fid, '%s,%s,%s,%s\r\n', ...
    sn_str, 'CC_angular_resolution', '1.076', bug);

fclose(fid);


end
