function [cal] = rad_read_ctdbp_cal(calfilename)
%.. desiderio 26-feb-2020: written to be used with previous functions named
%..                        analogously to read in ctdbp cal files so that
%..                        the values of the cal coeffs can be checked for
%..                        agreement: cal vs. QCT capfile vs. xmlcon.
%
%.. filename must include the full path of the infile unless
%.. the file is located in the working directory.
%
%.. cal coefficient names as read from the cal file.
%.. the conductivity coeffs have a 'C' prepended
coeff_name = {'TA0', 'TA1', 'TA2', 'TA3',      ...
              'PTEMPA0', 'PTEMPA1', 'PTEMPA2', ...
              'PTCA0', 'PTCA1', 'PTCA2',       ...
              'PTCB0', 'PTCB1', 'PTCB2',       ...
              'PA0', 'PA1', 'PA2',             ...
              'CG', 'CH', 'CI', 'CJ', 'CPCOR', 'CTCOR' };

%.. field names will follow xmlcon and pdf convention.
field_name = {'A0', 'A1', 'A2', 'A3',      ...
              'PTEMPA0', 'PTEMPA1', 'PTEMPA2', ...
              'PTCA0', 'PTCA1', 'PTCA2',       ...
              'PTCB0', 'PTCB1', 'PTCB2',       ...
              'PA0', 'PA1', 'PA2',             ...
              'G', 'H', 'I', 'J', 'CPCOR', 'CTCOR' };

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
cal.sernum = sscanf(str(idx+3:end), '%u');

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

%.. find the pressure sensor caldate
match = 'PCALDATE=';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Pressure coefficients');
end
str = C{idx};
%.. read caldate from characters after '='
idx = strfind(str, '=');
cal.caldate_pressure = strtrim(str(idx+1:end));

%.. populate the structure fields.
%
%.. USE EXACT MATCHES TO PREVENT THE POSSIBILITY OF CONFUSING
%.. 'PA#' WITH 'PTEMPA# = ' FOR #=1,2,3.
%
%.. so, do not use 'contains'
%
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
