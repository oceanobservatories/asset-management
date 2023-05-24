function optaaCalFileCheckFunction
%.. optaaCalFileCheck
%.. desiderio 2019-05-12
%.. desiderio 2019-08-02: discriminated against *.csv.url files
%.. desiderio 2019-08-04: this was a script; made into a function so that it
%..                       could be run inside of another program and not affect 
%..                       the variables in the other program's workspace.
%.. THE ONLY CHANGE WAS THE ADDITION OF THE FUNCTION STATEMENT (1st line of code).
%.. desiderio 2022-02-02: added documentation
%
%.. This code provides a means for checking the calibration coefficient arrays
%.. in the OPTAA vendor calfiles (devfiles) versus the 3 OOI csv calfiles
%.. generated from them. It creates an xlsx file with 5 sheets: the 1st contains
%.. the vendor devfile, the 3rd contains the OOI csv calfile values excluding the
%.. tc and ta arrays, the 4th and 5th contain the tc and ta arrays, respectively.
%.. and the 2nd testbed sheet contains formulas containing like coeffs from the
%.. 1st and 3-5th sheets and differences them for the 1st cell of each array. The
%.. user can then autofill the differences to compare the values in the OOI csv
%.. calfiles against those in the dev file.
%..
%.. Change working directory to one containing only one set of OPTAA calfiles:
%.. one devfile, and one triplet of files for the OOI csv files. The xlsx comparison
%.. file will be created in the same directory. 
%
%.. DO NOT USE STRING DATATYPE FOR XLSX FILENAMES.
%
%##########################################################################
%.. I included a "watermark" signature to make sure that the excel differencing
%.. operation, being used to validate the calibration coefficients in the
%.. OOI calfiles, does not have a sigfig issue. A patch of alternating differences
%.. of 1.e-7 will show up in the differencing auto-fill to selected ta and tc
%.. cells at upper right sections of these respective arrays on the testbed sheet.
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
%.. this code will write a formula into the top left cell of all ranges
%.. of calcoeffs to be tested.
%
%.. to check 1D arrays (in columns):
%.. (a) highlight upper cell
%.. (b) double click on lower right corner to auto-apply formula down
%
%.. to check 2D arrays:
%.. (a) highlight that upper left cell
%.. (b) Position cursor on lower right corner 
%.. (c) Depress left mouse key and drag across to last column and release 
%.. (d) Double click on the lower right corner of that cell

%.. get filenames including path
disp(['Working directory is ' pwd]);
listing = strtrim(cellstr(ls(pwd)));
%.. there may be internet shortcut links to github asset management which
%.. are named exactly as the OOI csv calfile but with '.url' appended.
listing(contains(listing, 'url')) = [];  % remove these
listing = strcat([pwd '\'], listing);                        % prepends path
devFile = char(listing(contains(listing, {'.dev' 'DEV'})));  % vendor calfile
csvFile = char(listing(contains(listing, '.csv')));          % OOI calfile
aaaFile = char(listing(contains(listing, 'taarray')));       % OOI calfile
cccFile = char(listing(contains(listing, 'tcarray')));       % OOI calfile
xlsxFile = strrep(devFile, 'dev', 'xlsx');                   % testbed file
xlsxFile = strrep(xlsxFile, 'DEV', 'xlsx');                  % testbed file

%.. make sure dev or DEV file isn't deleted
%.. (see nutnrCalFileCheck.m for documentation)
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

Excel = actxserver('Excel.Application');
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(devFile);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', 1);
thisSheet.Name = 'devfile';
Workbook.SaveAs(xlsxFile, 51);
Workbook.Close();
Excel.Quit();
Excel.delete();

%  write out test sheet where conditional format checking will be applied
[~, ~, raw] = xlsread(xlsxFile, 1);
if raw{end, 1}==0
    raw(end, :) = [];  % delete last 'stat' line 
end

nWave = raw{8, 1};
nTbin = raw{9, 1};

xlswrite(xlsxFile, raw, 'testbed');
clear raw

%.. read in csv file and write its info to its own sheet
fid = fopen(csvFile);
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', newline);
fclose(fid);
C = C{1};  % 'unwrap'
%.. don't need brackets
C = strrep(C, '[', '');
C = strrep(C, ']', '');
%.. rows could be in any order, but CC names are standardized
C(contains(C, {'taarray', 'tcarray'})) = [];
C(~strncmpi(C, 'ACS', 3))              = [];
C = sort(C);

%.. get CC_tcal; retain CC_ to denote that it came from OOI calfile
tf_tcalRow = contains(C, 'CC_tcal');
tcalRowText = C{tf_tcalRow};
newStr = split(tcalRowText, ','); 
CC_tcal = newStr(3);

C(tf_tcalRow) = [];
%.. ordering at this point:
%.. .. CC_acwo
%.. .. CC_awlngth
%.. .. CC_ccwo
%.. .. CC_cwlngth
%.. .. CC_tbins

D = split(C, '"');
%.. the first column of D has the CC names between two commas:
CC = split(D(:, 1), ',');
CC_names = CC(:, 2);
%.. the second column of D has the wavelength and offset vector data;
%.. the 1st 4 have the same number of delimiters
waveData  = split(D(1:4, 2), ',')';  % nWave values for each column
%.. the last has the tBin data
tbinValue = split(D(5, 2), ',')';    % nTbin values (row vector)

%.. construct cell array to mimic orientation of these parameters in devfile.
csvSheet(1:nWave, 1:5) = {''};
csvSheet(1, 3) = CC_tcal;  % put this at top between c data and a data
%.. condition waveData entries
%.. .. delete spaces that will interfere with prepending 'A' and 'C' ...
waveData = strtrim(waveData);
%.. .. to the wavelength values
waveData(:, 2) = strcat('A', waveData(:, 2));
waveData(:, 4) = strcat('C', waveData(:, 4));
csvSheet(:, [1 2 4 5]) = waveData(:, [4 2 3 1]);  % cwave, coff, awave, aoff
%.. except start the columns at top of the new sheet, with a header row.
csvSheetHeader(1, 3) = {'CC_tcal'};
csvSheetHeader(1, [1 2 4 5]) = CC_names([4 2 3 1]);
csvSheet = vertcat(csvSheetHeader, csvSheet);
%.. put in the tbin values as a row as it is in the dev file
lastTbinIdx = 5 + nTbin;
csvSheet(1, 6:lastTbinIdx) = tbinValue;
csvSheet(2, 6)             = {'CC_tbins'};
%.. put in calDate from csv filename, too, as a reminded to check that.
csvSheet(3, 3) = {'CC_caldate'};
csvSheet(4, 3) = calDate;
xlswrite(xlsxFile, csvSheet, 'csv');
%.. and increase column width to make date visible
setXlsxColumnWidths(xlsxFile, 'csv', 3, 16)

%.. OOI taarray and tcarray values are acceptable if the difference from
%.. the devfile values is within 1E-04.
%
%.. make sure that the excel differencing operation, being used to validate
%.. the calibration coefficients in the OOI calfiles, does not have a
%.. sigfig issue. Artificially add and subtract 1E-07 to selected ta and
%.. tc cells at upper right sections of the respective arrays.

epsln = 1.e-07;

tc_array = dlmread(cccFile);
tc_array(2:6, end-1) = tc_array(2:6, end-1) + epsln;
tc_array(2:6, end-2) = tc_array(2:6, end-2) - epsln;
tc_array(2:6, end-3) = tc_array(2:6, end-3) + epsln;
tc_array(2:6, end-4) = tc_array(2:6, end-4) - epsln;
tc_array(2:6, end-5) = tc_array(2:6, end-5) + epsln;
xlswrite(xlsxFile, tc_array, 'tc_array');

ta_array = dlmread(aaaFile);
ta_array(2:6, end-1) = ta_array(2:6, end-1) - epsln;
ta_array(2:6, end-2) = ta_array(2:6, end-2) + epsln;
ta_array(2:6, end-3) = ta_array(2:6, end-3) - epsln;
ta_array(2:6, end-4) = ta_array(2:6, end-4) + epsln;
ta_array(2:6, end-5) = ta_array(2:6, end-5) - epsln;
xlswrite(xlsxFile, ta_array, 'ta_array');

%.. write in formulae in upper left cells. make separate xlswrites for each
% CHECKS:

cwaveFormula = {'=exact(devfile!A11,csv!A2)'};
xlswrite(xlsxFile, cwaveFormula, 'testbed', 'A11:A11');
awaveFormula = {'=exact(devfile!B11,csv!B2)'};
xlswrite(xlsxFile, awaveFormula, 'testbed', 'B11:B11');

coffsetFormula = {'=devfile!D11-csv!D2'};
xlswrite(xlsxFile, coffsetFormula, 'testbed', 'D11:D11');
aoffsetFormula = {'=devfile!E11-csv!E2'};
xlswrite(xlsxFile, aoffsetFormula, 'testbed', 'E11:E11');

tbinFormula = {'=devfile!F10-csv!F1'};
xlswrite(xlsxFile, tbinFormula, 'testbed', 'F10:F10');

tcarrayFormula = {'=devfile!G11 - tc_array!A1'};
xlswrite(xlsxFile, tcarrayFormula, 'testbed', 'G11:G11');

%.. calculate out column designation for start column for ta_array
startColumn = 6 + nTbin + 2;  % blank column after last tc_array column
%.. note that char(65) = 'A';
secondLetter = char(startColumn - 26 + 64);
taCell = ['A' secondLetter '11'];
taRange = [taCell ':' taCell];

taarrayFormula = {['=devfile!' taCell  ' - ta_array!A1']};
xlswrite(xlsxFile, taarrayFormula, 'testbed', taRange);

taarrayReminder = {'Check-->'};
taRemRange      = 'J7:J7';
%.. and a reminder to check ta_array, because it will be off-screen right
xlswrite(xlsxFile, taarrayReminder, 'testbed', taRemRange);

%.. highlight cells for check reminders
cellsToCheck = {
    'A4:A4'                  % caltemp
    'F4:G4'                  % caldate
    'A11:A11'                % 'c' wavelengths
    'B11:B11'                % 'a' wavelengths
    'D11:D11'                % 'c' offsets
    'E11:E11'                % 'a' offsets
    'F10:F10'                % tbin values
    'G11:G11'                % tc_array
    taRange                  % ta_array
    taRemRange               % ta_array check reminder
    };
%.. 39 is a predefined excel color (lavender)
colorXlsxCells(xlsxFile, 'testbed', cellsToCheck, -39)

%.. also highlight the tcal and caldate values in the OOI calfile
colorXlsxCells(xlsxFile, 'csv', {'C2:C2' 'C4:C4'}, -39)
