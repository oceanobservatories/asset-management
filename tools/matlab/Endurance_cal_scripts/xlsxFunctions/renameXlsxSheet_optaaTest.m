%function renameXlsxSheet(xlsxName, oldSheetID, newSheetName)
%.. acsDevFileCheck - in developemnt
%.. desiderio 2019-05-11
%
% %.. xlsxName [character vector] must contain the full path
% %.. oldSheetID can either be the sheetName (character vector) or sheetNumber
% %.. sheetName must be a character vector

fpath = 'R:\test\';
devFileName = 'acs170.dev';
csvFileName = 'CGINS-OPTAAD-00170__20180816.csv';
aaaFileName = 'CGINS-OPTAAD-00170__20180816__CC_taarray.ext';
cccFileName = 'CGINS-OPTAAD-00170__20180816__CC_tcarray.ext';
%
devFile = [fpath devFileName];
csvFile = [fpath csvFileName];
aaaFile = [fpath aaaFileName];
cccFile = [fpath cccFileName];
xlsxFile = strrep(devFile, 'dev', 'xlsx');  % testbed file

Excel = actxserver('Excel.Application');
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(devFile);
Workbook.SaveAs(xlsxFile, 51);
Workbook.Close();
Excel.Quit();
Excel.delete();
