function [cal] = rad_read_presf_cap(txtfilename)
%.. desiderio 18-sep-2015
%.. desiderio 06-jun-2016
%.. desiderio 13-sep-2016 revised and generalized.
%.. desiderio 01-apr-2017  get sernum and caldate from inside file!
%.. desiderio 07-oct-2017 revised caldate parsing because of an
%..                       anomalous occurrence of '03-dec-2016' instead
%..                       of the expected '03-dec-16'.
%.. desiderio 20-mar-2018 MORE DATE ANOMALIES!
%..                       write whatever string is encountered; parse
%..                       it to make sense in write_presf_qct_to_csv.m
%
%.. reads in calcoeffs from Seabird 26+ text files into the output
%.. structure cal. Input files can either be 'cap' (captured) files
%.. from a QCT or hex files (because the calcoeffs in both are listed
%.. in the same way enabling a common read mechanism).
%
%.. filename must include the full path of the infile unless
%.. the file is located in the working directory.
%
%.. coefficient (and structure field) names.
%.. these are ordered as in Omaha xlsx sheets, although
%.. Omaha has both slope and offset correction coeffs
%.. which are not in the cal sheets.
coeff_name = {'C1', 'C2', 'C3',         ...
              'D1', 'D2',               ...
              'OFFSET',                 ...
              'T1', 'T2', 'T3', 'T4',   ...
              'U0',                     ...
              'Y1', 'Y2', 'Y3',         ...
              'B', 'M'                  ...
              'TA0', 'TA1', 'TA2', 'TA3'   };
              
fid = fopen(txtfilename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};
%.. get rid of leading and trailing spaces
C = strtrim(C);

%.. parse serial number into cal data structure.
idx = find(contains(C, 'SN'), 1);
if isempty(idx)
    error('Could not find serial number');
end
str = C{idx};
%.. read serial number from characters after 'SN' 
idx = strfind(str, 'SN');
cal.sernum = sscanf(str(idx+3:idx+7), '%u');

%.. find the pressure sensor caldate
match = 'Pressure coefficients:';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Pressure coefficients');
end
str = C{idx};
%.. read caldate from characters after ':'
idx = strfind(str, ':');
str = strtrim(str(idx+1:end));
cal.Pcal = str;

%.. find the temperature sensor caldate
match = 'Temperature coefficients:';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Temperature coefficients');
end
str = C{idx};
%.. read caldate from characters after ':'
idx = strfind(str, ':');
str = strtrim(str(idx+1:end));
cal.Tcal = str;

%.. populate the structure fields
for ii=1:length(coeff_name)
    idx = find(contains(C,[coeff_name{ii} ' = ']));
    if isempty(idx)
        cal.(coeff_name{ii}) = '';
    else
        %.. some of the cap files have coeffs written out twice;
        %.. just in case they could have been changed during the
        %.. SBE procedure, use last one.
        str = C{idx(end)};
        idx_eq = strfind(str, '=');
        cal.(coeff_name{ii}) = str(idx_eq+2:end);
    end
end

clearvars C