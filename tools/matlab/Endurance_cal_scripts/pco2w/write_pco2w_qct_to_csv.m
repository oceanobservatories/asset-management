function csvfilename = write_pco2w_qct_to_csv(qct)
%.. desiderio 14-sep-2018
%
%.. reads in cal values for a Sunburst SAMI pCO2 instrument (PCO2W)
%.. from the QCT to create an OOI GitHub cal file. 
%
%
%.. I have observed that sometimes there are less significant
%.. figures written out from the instrument's firmware than are
%.. displayed on the calibration certificate.
%
%..****************************************************
%.. AFTER GENERATING CSV FILE, ADD SIGFIGS TO CAL TEMP.
%..****************************************************
%
%..    All instruments are assumed to be series 'B' (Endurance)
%
%..    APPEND THE CALDATE FROM THE CAL CERTIFICATE TO THE QCT 
%..    FILENAME EXTENSION AS _YYYYMMDD: 
%..
%..    3305-00110-XXXXX-B_YYYYMMDD.txt

%.. sample:  start of QCT 3305-00110-00147-B.txt
%.. the date here is the date of the QCT, not the cal date
%..
% File created: 7 March 2018  00:32:39
% SAMI Client Version: 1.3.1
% :SAMIinfoHex
% 00372020202020202020202020433030363130323038 ... etc
% :SAMIinfo
% Firmware: 55
% Name:            C0061
% Serial Number: 0208
% Board version: 0E
% Board Configuration: C0
% Cal1: 0.0299
% Cal2: 0.7231
% Cal3: -1.6615
% Cal4: 6.13
% Cal5: 0.893
% Cal6: 0.8973
% :ConfigHex

disp(pwd)
disp('Check sigfigs for CalT and add by hand if necessary.');

%.. calcoeff order as in the QCTs above and Sunburst cal certificates:
match = { 'cala'   'calb'   'calc'   'calt' };
ccqct = { 'Cal1:'  'Cal2:'  'Cal3:'  'Cal4:'};

%.. calcoeffs in OOI csv calfile that change from cal to cal
ccOOI_name = {'CC_cala' 'CC_calb' 'CC_calc' 'CC_calt'};
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
    cc = C(strncmpi(C, match{ii}, 4));
    if isempty(cc)
        error(['PCO2W calcoeff ' match{ii} ' not found in ' ...
            qct]);
    elseif length(cc) ~= 1
        error(['More than one PCO2W calcoeff for ' match{ii} ...
             ' found in ' qct]);
    end
    calcoeff{ii} = strtrim(cc{1}(5:end));
end

%.. parse serial number from 'Name:' row
tf_Name = strncmpi(C, 'Name:', 5);
if sum(tf_Name)==0
    error('Could not find CXXXX serial number in the qct file.');
end
idx = find(tf_Name);
sernum = C{idx(1)};
sernum = strrep(sernum, 'Name:', '');
sernum = strtrim(sernum);

%.. find date of cal from filename;
%.. must be appended as YYYYMMDD before running this code.
idx = strfind(qct, '.txt');
caldate = qct(idx-8:idx-1);

%.. construct output filename
csvfilename = ['CGINS-PCO2WB-' sernum '__' caldate '.csv'];

%.. write directly out
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\r\n', header);
for ii=1:ncoeff
    fprintf(fid, '%s,%s,%s,\r\n', sernum, ccOOI_name{ii}, calcoeff{ii});
end
%.. these calcoeff entries do not change
%.. these calcoeffs do not change
Ea434 = '19706';
Ea620 =    '34';
Eb434 =  '3073';
Eb620 = '44327';
fprintf(fid, '%s,%s,%s,constant\r\n', sernum, 'CC_ea434', Ea434);
fprintf(fid, '%s,%s,%s,constant\r\n', sernum, 'CC_ea620', Ea620);
fprintf(fid, '%s,%s,%s,constant\r\n', sernum, 'CC_eb434', Eb434);
fprintf(fid, '%s,%s,%s,constant\r\n', sernum, 'CC_eb620', Eb620);

fclose(fid);

end
