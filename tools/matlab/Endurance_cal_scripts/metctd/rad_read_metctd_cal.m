function [cal] = rad_read_metctd_cal(calfilename)
%.. desiderio 30-jan-2023: read SBE sbe37 CT (metctd) *.cal file and output
%..                        calcoeffs and meta data in a structure. adapted
%..                        from rad_read_ctdbp_cal.m
%
%.. IN FACT, rad_read_ctdbp_cal.m reads the sbe37 file (almost) perfectly
%.. because that program was written for sbe16 CTDs, and those cal files
%.. are almost identical to the sbe37 calfiles. The differences are, that
%.. all the pressure calcoeffs in the sbe37 .cal files are either 0 or 1, 
%.. because it has no pressure sensor, AND they do contain an extra parm
%.. used for conductivity WBOTC.
%
%.. filename must include the full path of the infile unless
%.. the file is located in the working directory.
%
%.. cal coefficient names as read from the cal file.
%.. the conductivity coeffs have a 'C' prepended.
%
%.. omit the Pressure Coefficients
coeff_name = {
    'TA0',  'TA1',  'TA2',  'TA3',      ...
    'CG',  'CH',  'CI',  'CJ',          ...
    'CPCOR',  'CTCOR',  'WBOTC'         ... 
    }; 

%.. field names on output.
field_name = {
    'A0' 'A1' 'A2' 'A3'           ...
    'G' 'H' 'I' 'J'               ...
    'CPCOR' 'CTCOR' 'WBOTC'       ...
    };

fid = fopen(calfilename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};
C = strtrim(C);

%.. parse serial number into cal data structure.
idx = find(contains(C, 'SERIALNO='), 1);
if isempty(idx)
    error('Could not find serial number');
end
str = C{idx};
%.. read serial number from characters after 'NO=' 
idx = strfind(str, 'NO=');
tmp = sscanf(str(idx+3:end), '%u');
cal.sernum = num2str(tmp, '%5.5u');

%.. find the temperature sensor caldate
match = 'TCALDATE=';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Temperature coefficients');
end
str = C{idx};
%.. read caldate from characters after '='
idx = strfind(str, '=');
cal.caldate_temperature = strtrim(str(idx+1:end));

%.. find the conductivity sensor caldate
match = 'CCALDATE=';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Conductivity coefficients');
end
str = C{idx};
%.. read caldate from characters after '='
idx = strfind(str, '=');
cal.caldate_conductivity = strtrim(str(idx+1:end));


%.. populate the structure fields.
%.. also, be extra careful because of the coeff name 'I' and:
%.. .. (a) assume upper case
%.. .. (b) use '=' in the match
for ii=1:length(coeff_name)
    idx = find(strncmp(strtrim(C), ...
        [coeff_name{ii} '='], 1 + length(coeff_name{ii})));
    if isempty(idx)
        cal.(coeff_name{ii}) = '';
        disp([calfilename ' warning: '''' entry for ' coeff_name{ii}]);
    else
        %.. some of the cap files have coeffs written out twice;
        %.. just in case they could have been changed during the
        %.. SBE procedure, use last one.
        str = C{idx(end)};
        idx_eq = strfind(str, '=');
        cal.(field_name{ii}) = strtrim(str(idx_eq+1:end));
    end
end
