function [cal] = rad_read_spkir_cal(calfilename)
%.. desiderio 17-sep-2015
%.. read in calcoeffs from the input Satlantic cal file for the OCR-507
%.. into the output structure cal.
%
%.. filename must include the full path of the xmlconfile unless
%.. the file is located in the working directory.
%
%.. 01-apr-2017 added cal.date to structure

clear C

fid = fopen(calfilename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};

%.. parse serial number into cal data structure
idx_sn = 1 + find(~cellfun(@isempty, strfind(C,'INSTRUMENT')), 1);
cal.sernum = sscanf(C{idx_sn}(4:7), '%f');

%.. find the 7 rows with the actual wavelengths of the optical channels
%.. listed, even though this info is not listed in the Omaha calsheets.
idx = find(~cellfun(@isempty, strfind(C,'uW/cm^2/nm')));
cal.wvl = cellfun(@(x) sscanf(x(4:9), '%f'), C(idx));
%.. the calcoeff entries are on the following lines.
str = char(C(idx+1));
%.. add a tab at the end of each line to prepare for parsing
str(:,end+1) = char(9);
%.. parse to get the calcoeffs as elements of a cell array
Coeff = textscan(str', '%s', 21);
Coeff = reshape(Coeff{1}, [3 7]);
%.. order as they'll go into the Omaha xlsx sheet
cal.immersion_factor = Coeff(3,:)';
cal.offset           = Coeff(1,:)';
cal.scale            = Coeff(2,:)';

%.. find date of cal; contained in the last line of header 
%.. (contiguous rows at top of file starting with #).
%.. so, find first line that does not have a '#' in it,
%.. and backtrack one.
idx = find(cellfun(@isempty, strfind(C,'#')), 1) - 1;
%.. yyyy-mm-dd
cal.date = C{idx}(3:12);
clear C
