function [con] = rad_read_ctdbp_cap(capfilename)
%.. desiderio 30-sep-2017
%.. desiderio 01-aug-2019: modified to work with QCT logs which were turned 
%                          into pdfs so that I had to back-convert into txt.
%.. desiderio 11-sep-2019: the above 'fix' introduced a bug where the PA0
%                          coeff was incorrectly set to the PTEMPA0 value,
%                          same for PA1, PA2 (mutatis mutandis).
%.. desiderio 28-apr-2021: appended two spaces to the line containing the
%                          serial number so that 3 and 4 digit serial 
%                          could be read (for sbe49 on cspp).
%.. In any case, all calfiles on asset management were checked, none were
%.. contaminated.
%
%
%
%.. .. rad_read_ctdbp_cap operates on captured files from a SBE16+ CTD.
%.. .. created by modifying rad_read_presf_cap.m (SBE26+)
%
%.. reads in calcoeffs from Seabird 16+ text files into the output
%.. structure cal. Input files are 'cap' (captured) files from a QCT.
%..
%.. the cal information in the SBE16+ hex file header is in an xml
%.. format, so that if calcoeffs are to be read from a hex file,
%.. the script rad_read_ctdbp_xmlcon.m may work.
%
%.. filename must include the full path of the infile unless
%.. the file is located in the working directory.
%
%.. cal coefficient names as read from the cap file.
%.. the first 4 names are A0, A1, A2, and A3 in the xmlcon files
%..     and in the pdf documentation.
coeff_name = {'TA0', 'TA1', 'TA2', 'TA3',      ...
              'PTEMPA0', 'PTEMPA1', 'PTEMPA2', ...
              'PTCA0', 'PTCA1', 'PTCA2',       ...
              'PTCB0', 'PTCB1', 'PTCB2',       ...
              'PA0', 'PA1', 'PA2',             ...
              'G', 'H', 'I', 'J', 'CPCOR', 'CTCOR' };

%.. field names will follow xmlcon and pdf convention.
field_name = {'A0', 'A1', 'A2', 'A3',      ...
              'PTEMPA0', 'PTEMPA1', 'PTEMPA2', ...
              'PTCA0', 'PTCA1', 'PTCA2',       ...
              'PTCB0', 'PTCB1', 'PTCB2',       ...
              'PA0', 'PA1', 'PA2',             ...
              'G', 'H', 'I', 'J', 'CPCOR', 'CTCOR' };

fid = fopen(capfilename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};

%.. parse serial number into cal data structure.
idx = find(contains(C, 'SERIAL NO.'), 1);
if isempty(idx)
    error('Could not find serial number');
end
str = [C{idx} '  '];
%.. read serial number from characters after 'NO.' 
idx = strfind(str, 'NO.');
con.sernum = sscanf(str(idx+4:idx+8), '%u');

%.. find the temperature sensor caldate
match = 'temperature: ';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Temperature coefficients');
end
str = C{idx};
%.. read caldate from characters after ':'
idx = strfind(str, ':');
con.caldate_temperature = strtrim(str(idx+1:end));

%.. find the conductivity sensor caldate
match = 'conductivity: ';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Conductivity coefficients');
end
str = C{idx};
%.. read caldate from characters after ':'
idx = strfind(str, ':');
con.caldate_conductivity = strtrim(str(idx+1:end));

%.. find the pressure sensor caldate
match = 'pressure S/N = ';
idx = find(contains(C, match), 1);
if isempty(idx)
    error('Could not find Pressure coefficients');
end
str = C{idx};
%.. read caldate from characters after ':'
idx = strfind(str, ':');
con.caldate_pressure = strtrim(str(idx+1:end));

%.. populate the structure fields.
%
%.. USE EXACT MATCHES TO PREVENT THE POSSIBILITY OF CONFUSING
%.. 'PA#' WITH 'PTEMPA# = ' FOR #=1,2,3.
%
%.. so, do not use 'contains'
%
%.. also, be extra careful because of the coeff name 'I' and:
%.. .. (a) assume upper case
%.. .. (b) use ' = ' in the match
for ii=1:length(coeff_name)
    idx = find(strncmp(strtrim(C), ...
        [coeff_name{ii} ' = '], 3 + length(coeff_name{ii})));
    if isempty(idx)
        con.(coeff_name{ii}) = '';
        disp([capfilename ' warning: '''' entry for ' coeff_name{ii}]);
    else
        %.. some of the cap files have coeffs written out twice;
        %.. just in case they could have been changed during the
        %.. SBE procedure, use last one.
        str = C{idx(end)};
        idx_eq = strfind(str, '=');
        con.(field_name{ii}) = strtrim(str(idx_eq+2:end));
    end
end
