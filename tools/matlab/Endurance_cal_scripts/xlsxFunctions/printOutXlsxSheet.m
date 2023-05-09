function printOutXlsxSheet(xlsxName, sheetID)
%.. desiderio 2019-08-31
%
%.. xlsxName [character vector] must contain the full path.
%.. sheetID can either be the sheetName (character vector) or sheetNumber.

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);
thisSheet.PrintOut;
Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();

%.. to print out a bunch of acs xlsx logsheets on R
%.. (each of which only contains one worksheet):
%{
listing = cellstr(ls('*.xlsx'));
qlist = strcat('R:\', listing);
for ii=1:length(qlist),printOutXlsxSheet(qlist{ii}, 1),end
%}
