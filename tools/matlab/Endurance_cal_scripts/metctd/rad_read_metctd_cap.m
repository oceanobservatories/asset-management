function [con] = rad_read_metctd_cap(filename)
%.. desiderio 30-jan-2023: from rad_read_ctdbp_xmlcon
%..                        reads in calcoeffs from sbe37 captured QCT log
%..                        file. As opposed to the SBE16, whose captured
%..                        log files use the SBE *.cal file format to
%..                        display cal coeffs, the sbe37 firmware uses
%..                        an xml format.
%
%.. filename must include the full path of the xmlconfile unless
%.. the file is located in the working directory.

%.. coefficient (and structure field) names.
%.. these are ordered as in the SBE 37 cap files.
coeff_name = {'A0', 'A1', 'A2', 'A3',     ...
              'G', 'H', 'I', 'J',         ...
              'PCOR', 'TCOR', 'WBOTC' };
              
sensors = {'TEMP1', 'WBCOND0'};
          
fid = fopen(filename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};

%.. parse serial number into con data structure
SN     = C(contains(C, 'SERIAL NO. '));
idx    = strfind(SN{1}, 'SERIAL NO. ');
sernum = SN{1}(idx+11:idx+15);
%.. all the serial numbers are 5 dgits, except for 8028,
%.. which comes out as '8028 '
if sernum(end)==' '
    sernum = ['0' sernum(1:4)];
end
con.sernum = sernum;

%.. get caldates for each sensor.
nsensors = length(sensors);
caldate(1:nsensors) = {'No-Cal'};
for ii = 1:nsensors
    %.. caldate is listed 2 rows after the row match
    idx = 2 + find(contains(C, sensors{ii}));
    if isempty(idx), continue, end  % if no date found use initialized value
    sss = C{idx(1)};  % select 1st occurrence
    idx_ket = strfind(sss, '>');  % two of these in this xml line
    idx_bra = strfind(sss, '<');  % two of these in this xml line
    idx_range = (idx_ket(1)+1):(idx_bra(2)-1);
    caldate{ii} = sscanf(sss(idx_range), '%s');
end
con.caldate_temperature = caldate{1};
con.caldate_conductivity = caldate{2};

%.. use this same algorithm to populate the structure fields
for ii=1:length(coeff_name)
    D = C(contains(C, ['<' coeff_name{ii} '>']));
    %.. on output. to be consistent with the SBE16 (CTDBP) calcoeff names:
    if contains(coeff_name{ii}, 'COR')
        coeff_name{ii} = ['C' coeff_name{ii}];
    end
    if isempty(D)
        con.(upper(coeff_name{ii})) = '';
        continue
    end
    sss = D{1};
    idx_ket = strfind(sss, '>');  % two of these in this xml line
    idx_bra = strfind(sss, '<');  % two of these in this xml line
    idx_range = (idx_ket(1)+1):(idx_bra(2)-1);
    con.(upper(coeff_name{ii})) = sscanf(sss(idx_range), '%s');
end
