function write_parad_dev_to_csv(dev)
%.. desiderio 01-jun-2017
%
%.. reads in a PARADJ dev file for a cspp and writes out the 
%.. calibration coefficients to an OOI GitHub cal file.

%.. dev file  PARS-505.dev (tab delimited)
%
% ECO           tab    PARS-505	
% Created on:   tab    11/08/16	
% 		
% COLUMNS=3
% DATE=1	
% TIME=2	
% PAR=3
% im=           tab    1.3589	
% a1=           tab    2890	
% a0=           tab    4431	

caldate_provenance = 'date in filename comes from factory devfile';

clearvars C D

fid = fopen(dev);
%.. read in all lines. seems as if there may be some variation in the use
%.. of spaces and tabs, so:
C = textscan(fid, '%s%s', 'delimiter', '\t', ...
    'MultipleDelimsAsOne', 1);
fclose(fid);
%.. C is a 1x2 cell array of strings:
%..     column 1 has identifier strings 
%..     column 2 has S/N, caldate, and calcoeffs

%.. parse serial number from first line of devfile
idx = find(~cellfun(@isempty, strfind(C{2},'PARS-')), 1);
Sn = textscan(C{2}{idx}, '%s%u', 'delimiter', '-');
sernum = Sn{2};

%.. now convert serial number to 5 characters for calfilename
sn_str = num2str(sernum, '%5.5u');

%.. find date of cal
idx = find(~cellfun(@isempty, strfind(lower(C{1}),'created')), 1);
calstring = C{2}{idx};  % generalize read for permutations of m/d/yy
D = textscan(calstring,'%u%c%u%c%u');
yyyy = num2str(D{5}, '%4.4u');
yyyy(1) = '2';  % should be good for some years.
mm = num2str(D{1}, '%2.2u');
dd = num2str(D{3}, '%2.2u');
caldate = [yyyy mm dd];

%.. parse for immersion factor, a1, and a0.
idx = find(~cellfun(@isempty, strfind(C{1},'im')), 1);
Im = C{2}{idx};
idx = find(~cellfun(@isempty, strfind(C{1},'a1')), 1);
a1 = C{2}{idx};
idx = find(~cellfun(@isempty, strfind(C{1},'a0')), 1);
a0 = C{2}{idx};

%.. construct output filename
csvfilename = ['CGINS-PARADJ-' sn_str '__' caldate '.csv'];

%.. write directly out to a text file, no xlsx in-between.
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\n', header);

fprintf(fid, '%u,%s,%s,%s\n', sernum, 'CC_Im', Im, caldate_provenance);
fprintf(fid, '%u,%s,%s,%s\n', sernum, 'CC_a0', a0, 'digital');
fprintf(fid, '%u,%s,%s,%s\n', sernum, 'CC_a1', a1, 'digital');

fclose(fid);

end
