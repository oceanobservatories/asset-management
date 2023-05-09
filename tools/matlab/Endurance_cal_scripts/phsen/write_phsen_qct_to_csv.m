function csvfilename = write_phsen_qct_to_csv(qct)
%.. desiderio 14-sep-2018
%.. desiderio 05-jan-2023 added CC_sami_bits, 12
%.. desiderio 17-feb-2023 finding caldate now insensitive to qct extension
%
%.. reads in cal values for a Sunburst SAMI pH instrument (PHSEN)
%.. from the QCT to create an OOI GitHub cal file. 
%
%..    All instruments are assumed to be series 'D' (Endurance)
%
%..    APPEND THE CALDATE FROM THE CAL CERTIFICATE TO THE QCT 
%..    FILENAME EXTENSION AS _YYYYMMDD: 
%..
%..    3305-00109-XXXXX-B_YYYYMMDD.txt

%.. sample:  start of QCT 3305-00109-00220-B.txt
%.. the date here is the date of the QCT, not the cal date
%..
% File created: Friday, June 29, 2018  12:13:04 AM
% SAMI Client Version: 1.3.1
% :SAMIinfoHex
% 00372020202020202020202020503030383830323237304550304 ... etc
% :SAMIinfo
% Firmware: 55
% Name:            P0088
% Serial Number: 0227
% Board version: 0E
% Board Configuration: P0
% Cal1: 18217
% Cal2: 2216
% Cal3: 13
% Cal4: 40587
% Cal5: 0.08
% Cal6: 3
% :ConfigHex
%
%.. The pdf calibration certificate and the OOI csv calfile are opened in
%.. Acrobat and Notepad, respectively,  for consistency check.
%

disp(pwd)

%.. calcoeff order as in the QCTs above and Sunburst cal certificates:
match = {'Ea_434' 'Eb_434' 'Ea_578' 'Eb_578'};
ccqct = { 'Cal1:'  'Cal2:'  'Cal3:'  'Cal4:'};

%.. calcoeffs in OOI csv calfile that change from cal to cal
ccOOI_name = {'CC_ea434' 'CC_eb434' 'CC_ea578' 'CC_eb578'};
ncoeff = length(ccOOI_name);

fid = fopen(qct);
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
C = C{1};
fclose(fid);
C = strrep(C, char(9), ' ');  % replace tabs by spaces

%.. to make sure that there is only one copy of the calcoeffs,
%.. delete everything after the 1st execution of :SAMIinfo;
%.. first remove :SAMIinfoHex
C = strrep(C, ':SAMIinfoHex', 'ZZTop');
tf_SAMIinfo = contains(C, ':SAMIinfo');
if sum(tf_SAMIinfo)==0
    error('No '':SAMIinfo'' calcoeffs in the qct file.');
end
idx = find(tf_SAMIinfo);
C(idx(1)+12:end)=[];

%.. replace 'CalX' with 'match' entries
for ii=1:ncoeff
    C = strrep(C, ccqct{ii}, match{ii});
end

calcoeff(1:ncoeff) = {''};
for ii = 1:ncoeff
    cc = C(strncmpi(C, match{ii}, 6));
    if isempty(cc)
        error(['PHSEN calcoeff ' match{ii} ' not found in ' ...
            qct]);
    elseif length(cc) ~= 1
        error(['More than one PHSEN calcoeff for ' match{ii} ...
             ' found in ' qct]);
    end
    calcoeff{ii} = strtrim(cc{1}(7:end));
end

%.. parse serial number from 'Name:' row
tf_Name = strncmpi(C, 'Name:', 5);
if sum(tf_Name)==0
    error('Could not find PXXXX serial number in the qct file.');
end
idx = find(tf_Name);
sernum = C{idx(1)};
sernum = strrep(sernum, 'Name:', '');
sernum = strtrim(sernum);

%.. find date of cal from filename;
%.. must be appended as YYYYMMDD before running this code.
[~, name, ~] = fileparts(qct);
caldate      = name(end-7:end);

%.. construct output filename
csvfilename = ['CGINS-PHSEND-' sernum '__' caldate '.csv'];

%.. write directly out
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\n', header);
for ii=1:ncoeff
    fprintf(fid, '%s,%s,%s,\n', sernum, ccOOI_name{ii}, calcoeff{ii});
end
%.. these calcoeff entries do not change
fprintf(fid, '%s,%s,\n', sernum, 'CC_ind_off,0');
fprintf(fid, '%s,%s,\n', sernum, 'CC_ind_slp,1');
fprintf(fid, '%s,%s\n', sernum, ['CC_psal,35,' ...
    'DELETE: use salinity from co-located CTDBP']);
fprintf(fid, '%s,%s,%s,\n', sernum, 'CC_sami_bits', '12');

fclose(fid);

%.. now check the OOI csv calfile coeffs.
%.. .. open the pdf file first, because using notepad introduces
%.. .. an automatic pause in code execution which can be used
%.. .. to compare the coeffs. when notepad is closed, execution
%.. .. will continue.
pdfFilename = ls('*.pdf');
if isempty(pdfFilename)
    disp('No pdf file found in instrument folder. Continue.');
else
    open(pdfFilename);
end
system(['notepad ' csvfilename]);
end
