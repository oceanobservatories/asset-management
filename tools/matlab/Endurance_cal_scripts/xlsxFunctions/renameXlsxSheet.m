function renameXlsxSheet(xlsxName, oldSheetID, newSheetName)
%.. desiderio 2019-04-30
%
%.. xlsxName [character vector] must contain the full path
%.. oldSheetID can either be the sheetName (character vector) or sheetNumber
%.. sheetName must be a character vector

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', oldSheetID);
thisSheet.Name = newSheetName;
Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
