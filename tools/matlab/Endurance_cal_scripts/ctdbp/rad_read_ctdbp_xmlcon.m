function [con] = rad_read_ctdbp_xmlcon(filename)
%.. desiderio 17-sep-2015
%..           26-feb-2020: changed fieldnames CPcor and CTcor to
%..                        CPCOR and CTCOR to be consistent with
%..                        qct cap and cal files.
%..
%..                        also updated code to use 'contains'
%..                        
%
%.. read in calcoeffs from the input Seabird xmlcon file into the
%.. output structure con.
%
%.. filename must include the full path of the xmlconfile unless
%.. the file is located in the working directory.

clear coeff_name sensors C caldate

%.. coefficient (and structure field) names.
%.. these are ordered as in Omaha xlsx sheets.
coeff_name = {'A0', 'A1', 'A2', 'A3',          ...
              'PTEMPA0', 'PTEMPA1', 'PTEMPA2', ...
              'PTCA0', 'PTCA1', 'PTCA2',       ...
              'PTCB0', 'PTCB1', 'PTCB2',       ...
              'PA0', 'PA1', 'PA2',             ...
              'G', 'H', 'I', 'J', 'CPcor', 'CTcor' };
              
sensors = {'Temperature', 'Conductivity', 'Pressure'};
          
fid = fopen(filename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};

%.. parse serial number into con data structure
%idx_sn = find(~cellfun(@isempty, strfind(C,'<SerialNumber>')), 1);
idx_sn = contains(C, '<SerialNumber>');
str = C{idx_sn};
idx_ket = strfind(str, '>');  % two of these in this xml line
idx_bra = strfind(str, '<');  % two of these in this xml line
idx_range = (idx_ket(1)+1):(idx_bra(2)-1);
con.sernum = sscanf(str(idx_range), '%u');

%.. find the calibration dates of the TCP sensors.
nsensors = length(sensors);
caldate{nsensors} = nan;
for ii = 1:nsensors
    %.. caldate is listed 2 rows after the row match
    match = [sensors{ii} 'Sensor SensorID'];
    %idx = 2 + find(~cellfun(@isempty, strfind(C, match)), 1);
    idx = 2 + find(contains(C, match));
    str = C{idx};
    idx_ket = strfind(str, '>');  % two of these in this xml line
    idx_bra = strfind(str, '<');  % two of these in this xml line
    idx_range = (idx_ket(1)+1):(idx_bra(2)-1);
    caldate{ii} = sscanf(str(idx_range), '%s');
end
con.caldate_temperature = caldate{1};
con.caldate_conductivity = caldate{2};
con.caldate_pressure = caldate{3};

%.. use this same algorithm to populate the structure fields
for ii=1:length(coeff_name)
    %idx = find(~cellfun(@isempty, strfind(C,['<' coeff_name{ii} '>'])), 1);
    idx = contains(C, ['<' coeff_name{ii} '>']);
    str = C{idx};
    idx_ket = strfind(str, '>');  % two of these in this xml line
    idx_bra = strfind(str, '<');  % two of these in this xml line
    idx_range = (idx_ket(1)+1):(idx_bra(2)-1);
    con.(upper(coeff_name{ii})) = sscanf(str(idx_range), '%s');
end

% clear C
