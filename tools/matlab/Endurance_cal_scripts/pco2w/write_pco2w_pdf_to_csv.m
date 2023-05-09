function csvfilename = write_pco2w_pdf_to_csv(pdf)
%.. desiderio 05-jan-2023
%
%.. reads in cal values for a Sunburst SAMI pCO2 instrument (PCO2W) from
%.. the calibration certificate PDF file to create an OOI GitHub cal file. 
%
%.. VALID ONLY FOR THE MORE RECENT CERTIFICATES - Sunburst changed the format:
%
%********************CASE B (newer)***********************
%
%     Table 1: SAMI2 CO2 calibration parameters.  
%      
%      A B C K434 K620 Tavg Range (ppm)
%      0.0946 0.2186 -0.8143 0.9227 1.4228 10.8670 204?1891
%********************CASE B (newer)***********************
%
%.. Also adds 2 more rows into the OOI csv calfiles, to denote
%.. (a) sami_bits = 12 unless Rev K board, then 14; i think that all 
%..     Endurance PCO2W and PHSEN instruments are currently 12 bit).
%.. (b) new CC calrange value to be included.
%
%..    All instruments are assumed to be OOI series 'B' (Endurance)
%..    (not related to case(B))
%
%.. The pdf calibration certificate and the OOI csv calfile are opened in
%.. Acrobat and Notepad, respectively,  for consistency check.
%
provenance = ['coeffs from ' pdf]; 

month = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

Month = {
    'January'
    'February'
    'March'
    'April'
    'May'
    'June'
    'July'
    'August'
    'September'
    'October'
    'November'
    'December'
    };

disp(pwd)

%.. calcoeffs in OOI csv calfile that change from cal to cal
ccOOI_name = {'CC_cala' 'CC_calb' 'CC_calc' 'CC_calt'};
ncoeff = length(ccOOI_name);

matchCaseA = 'Calibration Range (ppm):';  % old style (not supported)
matchCaseB = 'Table';                     % new style 2 occurrences of 'Table'

cert = extractFileText(pdf, 'Pages', 1);  % cert is a string

%.. determine certificate format
if contains(cert, matchCaseA)
    disp('Cal certificate pdf is in old format. No action taken.')
    return
elseif ~contains(cert, matchCaseB)
    disp('Format of pdf infile not recognized as valid. No action taken.')
    return
end

%.. get the cal coeffs - they are A, B, C, and Tavg
row = strsplit(cert, '\n')';
%.. find the row with the most numbers in it
numbers(1:numel(row)) = {'-.0123456789'};
[~, idxRow] = max(cellfun(@(x,y)sum(ismember(x, y)), row, numbers'));
%disp(maxN);
value = strsplit(row(idxRow), ' ');
%.. these are in the columns below (1 2 3 6).
calcoeff = value([1 2 3 6]);
%.. now get calRange
tokn = value{end};  % this is it except for a separator char in the middle
tokn(~ismember(tokn, '.0123456789')) = ',';  % replace separator with a comma

%.. check to make sure calcert listed range as [min-max]. if not fix.
vals = str2num(tokn);  %#ok
%.. write out with brackets enclosed with double quotes

calRange = ['"[' num2str(min(vals)) ',' num2str(max(vals)) ']"'];

%.. parse serial number from inside pdf file
snRow = char(row(contains(row, 'Serial Number:')));
snstr = strtrim(snRow(numel('Serial Number:')+1:end));
%.. the serial number may look like C85 or C0085 ... or 'SAMI' or ''
%.. or ... C126; even C5, although low SN aren't in OOI.
%.. .. ensure that the SN is formatted as Cxxxx where leading x are 0
%.. .. if necessary
if isempty(snstr)
    disp('Serial number from inside pdf file: blank')
    sernumI = '';
elseif contains(snstr, 'SAMI', 'IgnoreCase', true)
    disp('Serial number from inside pdf file: ''SAMI''')
    sernumI = '';
else
    disp(['Serial number from inside pdf file: ' snstr])
    snstr = upper([snstr(1) '000' snstr(2:end)]);
    sernumI = [snstr(1) snstr(end-3:end)];
    %disp(['Serial number from inside pdf file: ' sernumI])
end

%.. also look for serial number in pdf filename
%.. I will rename anomalous filenames from Vault to follow the
%.. OOI SAMI uid naming convention (Cxxxx for PCO2W) delimited
%.. by underscores.
toks = strsplit(pdf, {'_' '-' '.'});
tf_5_char  = cellfun('length', toks) == 5;
tf_C_start = strncmp(toks, 'C', 1);
sernumO    = char(toks(tf_5_char & tf_C_start));
disp(['Serial number from pdf filename:    ' sernumO])
 
if ~isempty(sernumI)
    sernum = sernumI;
else
    sernum = sernumO;
end
disp(['Serial number used for csv calfile: ' sernum])

%.. now date
rowDate = row(contains(row, Month, 'IgnoreCase', true));
if isempty(rowDate)  % typo in back end of month's long name? if so:
    rowDate = row(contains(row, month, 'IgnoreCase', true));
end
if ~isscalar(rowDate)
    disp(['Number of rows with month: ' numel(rowDate)]);
    error('Problem parsing pco2w caldate from inside of pdf.')
end
tokDate   = strsplit(rowDate, {' ' ','});
charYear  = char(tokDate(end));
charMonth = num2str(find(contains(Month, tokDate)), '%2.2u');
charDay   = num2str(str2num(tokDate(end-1)), '%2.2u');  %#ok
caldate   = [charYear charMonth charDay];

%.. construct output filename
csvfilename = ['CGINS-PCO2WB-' sernum '__' caldate '.csv'];

%.. write directly out
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\n', header);
fprintf(fid, '%s,%s,%s,%s\n', sernum, ccOOI_name{1}, calcoeff{1}, provenance);
for ii=2:ncoeff
    fprintf(fid, '%s,%s,%s,\n', sernum, ccOOI_name{ii}, calcoeff{ii});
end
%.. the next 4 calcoeff entries do not change
Ea434 = '19706';
Ea620 =    '34';
Eb434 =  '3073';
Eb620 = '44327';
fprintf(fid, '%s,%s,%s,constant\n', sernum, 'CC_ea434', Ea434);
fprintf(fid, '%s,%s,%s,constant\n', sernum, 'CC_ea620', Ea620);
fprintf(fid, '%s,%s,%s,constant\n', sernum, 'CC_eb434', Eb434);
fprintf(fid, '%s,%s,%s,constant\n', sernum, 'CC_eb620', Eb620);
%.. these 2 rows came into being at the start of 2023, although the
%.. DPAs haven't been modified to use them yet.
fprintf(fid, '%s,%s,%s,\n', sernum, 'CC_sami_bits', '12');
fprintf(fid, '%s,%s,%s,\n', sernum, 'CC_cal_range', calRange);

fclose(fid);

%.. now check the OOI csv calfile coeffs.
%.. .. open the pdf file first, because using notepad introduces
%.. .. an automatic pause in code execution which can be used
%.. .. to compare the coeffs. when notepad is closed, execution
%.. .. will continue.
if isempty(pdf)
    disp('No pdf file found in instrument folder. Continue.');
else
    open(pdf);
end
system(['notepad ' csvfilename]);
end
