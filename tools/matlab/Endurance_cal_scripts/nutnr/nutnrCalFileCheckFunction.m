function nutnrCalFileCheckFunction
%.. nutnrCalFileCheck
%.. desiderio 2019-05-12
%.. desiderio 2019-08-02: discriminated against *.csv.url files
%.. desiderio 2019-08-04: this was a script; made into a function so that it
%..                       could be run inside of another program and not affect 
%..                       the variables in the other program's workspace.
%.. THE ONLY CHANGE WAS THE ADDITION OF THE FUNCTION STATEMENT (1st line of code).
%.. desiderio 2022-02-02: added documentation
%
%.. This code provides a means for checking the calibration coefficient arrays
%.. in the NUTNR (SUNA and ISUS) vendor calfiles versus the OOI csv calfiles
%.. generated from them. It creates an xlsx file with 3 sheets: the 1st contains
%.. the vendor calfile values, the 3rd contains the OOI csv calfile values,
%.. and the middle contains formulas containing like coeffs from the 1st and 3rd
%.. sheets and differences them for the 1sst row of the arrays. The user can then
%.. autofill to check all 256 row differences.
%..
%.. The values in the 4th column in the vendor calfile are obsolete and not
%.. used to calculate nitrate concentration.
%
%.. Change working directory to one containing only one set of NUTNR calfiles:
%.. DO NOT USE STRING DATATYPE FOR XLSX FILENAMES. The xlsx comparison file
%.. will be created in the same directory.
%
%##########################################################################
%.. I included a "watermark" signature - a patch of alternating differences
%.. of 1.e-7 will show up in the differencing auto-fill. see documentation
%.. in code at watermark creation.
%##########################################################################
%
%.. if code crashes and there are excel problems from matlab command window,
%.. execute the following (at the matlab prompt):
%
%****************************************
%.. system('taskkill /F /IM EXCEL.EXE');
%****************************************
%
%.. calcoeff checks and keyboard shorcuts:
%
%.. this code will write a formula into the top cell of all ranges
%.. of calcoeffs to be tested.
%
%.. to check 1D arrays (in columns):
%.. (a) highlight upper cell
%.. (b) double click on lower right corner to auto-apply formula down
%

clear
nWave = 256;  % 256 pixel diode array used for both SUNAs and ISUSs

%.. get filenames including path
disp(' ');
disp(['Working directory is ' pwd])
listing = strtrim(cellstr(ls(pwd)));
%.. there may be internet shortcut links to github asset management which
%.. are named exactly as the OOI csv calfile but with '.url' appended.
listing(contains(listing, 'url')) = [];  % remove these
listing = strcat([pwd '\'], listing);                         % prepends path
%.. need to take into account '.cal' vs. 'CAL' designations ...
calFile = char(listing(contains(listing, {'.cal' '.CAL'})));  % vendor calfile
csvFile = char(listing(contains(listing, '.csv')));           % OOI calfile
xlsxFile = strrep(calFile, '.cal', '.xlsx');                  % testbed file
xlsxFile = strrep(xlsxFile, '.CAL', '.xlsx');                 % testbed file
%.. ... else the calfile itself can be deleted below!
%.. make sure this can't happen
[~, ~, ext] = fileparts(xlsxFile);
if ~contains(ext, 'xls')
    error('Check calfilename against testbed xlsx filename!');
end

%.. delete testbed file if it exists
if isfile(xlsxFile)
    delete(xlsxFile);
end 

warning('off', 'MATLAB:xlswrite:AddSheet');

ddd = split(csvFile, {'__', '.'});
ddd = ddd{end-1};  % cspp full paths also contain '__'
calDate = {[ddd(1:4) '_' ddd(5:6) '_' ddd(7:8)]};  % underscores!

%.. open calfile 
fid = fopen(calFile);
formatSpec = '%s%s%s%s%s%s%[^\n\r]';
C = textscan(fid, formatSpec, 'Delimiter', ',', 'CollectOutput', 1);
C = C{1};
fclose(fid);
%.. usually excel templates will have 3 sheets; I'd rather not end up
%.. with 3 calsheets plus 3 sheets labelled Sheet1,2,3 
xlswrite(xlsxFile, C, 1);
renameXlsxSheet(xlsxFile, 1, 'calfile')
xlswrite(xlsxFile, C, 2);
renameXlsxSheet(xlsxFile, 2, 'testbed')
%.. find the row number of the first calcoeff row
idx_firstRowData = find(contains(C(:, 1), {'E' 'e'}), 1);
clear C

%.. read in csv file and write its info to its own sheet
fid = fopen(csvFile);
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', newline);
fclose(fid);
C = C{1};  % 'unwrap'
%.. don't need brackets
C = strrep(C, '[', '');
C = strrep(C, ']', '');
%.. rows could be in any order, but CC names are standardized
%.. get rid of header row
C(contains(C, ('serial,name'))) = [];
C = sort(C);

%.. the 'JSON' format of the OOI csv calfiles can lead to an extra set
%.. of double quotes. The second set will be in the Notes section (4th
%.. column); however, cannot use comma as a delimiter because commas
%.. separate the JSON array elements. the second set must be dealt with
%.. so that the split on " statement after the ordering won't croak.
idxDoubleQuotes = strfind(C, '"');  % cell array
n_idxDoubleQuotes = cellfun('length', idxDoubleQuotes);
rowsWith4DoubleQuotes = find(n_idxDoubleQuotes==4);
for ii = 1:length(rowsWith4DoubleQuotes)  % 1:0 is not executed
    idx2ndSet = idxDoubleQuotes{rowsWith4DoubleQuotes}([3 4]);
    C{rowsWith4DoubleQuotes}(idx2ndSet) = '&';
end

%.. get CC_cal_temp; retain CC_ to denote that it came from OOI calfile
tf_tcalRow = contains(C, 'CC_cal_temp');
tcalRowText = C{tf_tcalRow};
newStr = split(tcalRowText, ','); 
CC_cal_temp = newStr(3);
C(tf_tcalRow) = [];

%.. also grab wavelength limits for spectral fits, even though these
%.. are SUNA settings and not calibration coefficients (and are not in
%.. the cal file).
tf_lower = contains(C, 'CC_lower_wavelength');
lowerText = C{tf_lower};
newStr = split(lowerText, ','); 
CC_lower_wavelength = newStr(3);
C(tf_lower) = [];
%
tf_upper = contains(C, 'CC_upper_wavelength');
upperText = C{tf_upper};
newStr = split(upperText, ','); 
CC_upper_wavelength = newStr(3);
C(tf_upper) = [];

%.. ordering at this point:
%.. .. CC_di          DI water reference spectrum
%.. .. CC_eno3        nitrate extinction coefficients
%.. .. CC_eswa        seawater extinction coefficients
%.. .. CC_wl          wavelengths

D = split(C, '"');
%.. the first column of D has the CC names between two commas:
CC = split(D(:, 1), ',');
CC_names = CC(:, 2);
%.. the second column of D has the calcoeff values;
%.. all 4 have the same number of delimiters
waveData  = split(D(:, 2), ',')';  % nWave values for each column


% tc_array = dlmread(cccFile);
% tc_array(2:6, end-1) = tc_array(2:6, end-1) + epsln;
% tc_array(2:6, end-2) = tc_array(2:6, end-2) - epsln;
% tc_array(2:6, end-3) = tc_array(2:6, end-3) + epsln;
% tc_array(2:6, end-4) = tc_array(2:6, end-4) - epsln;
% tc_array(2:6, end-5) = tc_array(2:6, end-5) + epsln;
% xlswrite(xlsxFile, tc_array, 'tc_array');
% 
% ta_array = dlmread(aaaFile);
% ta_array(2:6, end-1) = ta_array(2:6, end-1) - epsln;
% ta_array(2:6, end-2) = ta_array(2:6, end-2) + epsln;
% ta_array(2:6, end-3) = ta_array(2:6, end-3) - epsln;
% ta_array(2:6, end-4) = ta_array(2:6, end-4) + epsln;
% ta_array(2:6, end-5) = ta_array(2:6, end-5) - epsln;
% xlswrite(xlsxFile, ta_array, 'ta_array');


%.. construct cell array to mimic orientation of these parameters in calfile.
csvSheet(1:nWave, 1:6) = {''};
csvSheet(1, 1) = CC_cal_temp;  % put this at top left
%.. re-orient waveData entries to match calfile column positions
csvSheet(:, [2 3 4 6]) = waveData(:, [4 2 3 1]);  % wl, eno3, eswa, di
%.. except start the columns at top of the new sheet, with a header row.
csvSheetHeader(1, 1) = {'CC_tcal'};
csvSheetHeader(1, [2 3 4 6]) = CC_names([4 2 3 1]);
csvSheet = vertcat(csvSheetHeader, csvSheet);
%.. add wavelength limits as an afterthought
csvSheet(1, 7) = {'CC_lower_wavelength'};
csvSheet(2, 7) = CC_lower_wavelength;
csvSheet(3, 7) = {'CC_upper_wavelength'};
csvSheet(4, 7) = CC_upper_wavelength;

%.. put in calDate from csv filename, too, as a reminded to check that.
csvSheet(3, 1) = {'CC_caldate'};
csvSheet(4, 1) = calDate;
xlswrite(xlsxFile, csvSheet, 3);
renameXlsxSheet(xlsxFile, 3, 'csv')
%.. and increase column width to make date visible
setXlsxColumnWidths(xlsxFile, 'csv', 1, 12)

%.. WATERMARK CREATION
%.. in this section I will add and subtract a very small number from
%.. calcoeffs near the top of the table (which are not used in the
%.. spectral fit calculations) to make sure enough sigfigs will be
%.. displayed for excel differencing operations. the number is small
%.. enough such that even if any calcoeff was off by this amount the
%.. final data product values would not be changed with respect to
%.. the instrument's precision.
epsln = 1.e-07;
epsRange = 'B5:F9';
arr = xlsread(xlsxFile, 'csv', epsRange);
arr([1 3 5], [1 2 3 5]) = arr([1 3 5], [1 2 3 5]) - epsln;
arr([ 2 4],  [1 2 3 5]) = arr([ 2 4],  [1 2 3 5]) + epsln;

xlswrite(xlsxFile, arr, 'csv', epsRange); 

% CHECKS:
%.. write in formulae in top cells. make separate xlswrites for each
%
%.. nutnr calfiles can have a variable number of text rows before 
%.. the calcoeffs.
rr = num2str(idx_firstRowData);

cr = ['B' rr];
rrange{1} = [cr ':' cr];
waveFormula = {['=calfile!' cr '-' 'csv!B2']};
xlswrite(xlsxFile, waveFormula, 'testbed', rrange{1});

cr = ['C' rr];
rrange{2} = [cr ':' cr];
eno3Formula = {['=calfile!' cr '-' 'csv!C2']};
xlswrite(xlsxFile, eno3Formula, 'testbed', rrange{2});

cr = ['D' rr];
rrange{3} = [cr ':' cr];
eswaFormula = {['=calfile!' cr '-' 'csv!D2']};
xlswrite(xlsxFile, eswaFormula, 'testbed', rrange{3});

cr = ['F' rr];
rrange{4} = [cr ':' cr];
diFormula = {['=calfile!' cr '-' 'csv!F2']};
xlswrite(xlsxFile, diFormula,   'testbed', rrange{4});

%.. highlight cells for check reminders
%.. 39 is a predefined excel color (lavender)
colorXlsxCells(xlsxFile, 'testbed', rrange, -39)

%.. also highlight the tcal and caldate values in the OOI calfile
colorXlsxCells(xlsxFile, 'csv', {'A2:A2' 'A4:A4'}, -39)

%.. and wavelength limits, shouls always be 217 and 240
colorXlsxCells(xlsxFile, 'csv', {'G2:G2' 'G4:G4'}, -39)

disp(' ');
disp('CHECK LOWER AND UPPER WAVELENGTH LIMITS on csv sheet;');
disp('Should always be 217 and 240.');
disp(' ');

%.. also copy all check files to one place  
copyfile(xlsxFile, 'R:\');
