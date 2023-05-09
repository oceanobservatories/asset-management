function setXlsxDecimalPlaces(xlsxName, sheetID, cellsToFormat, format)
%.. desiderio 2020-11-18
%
%.. sets the number of decimal places in a range of excel cells.
%.. .. xlsxName [character vector] must contain the full path
%.. .. sheetID can either be the sheetName (character vector) or sheetNumber
%.. .. cells2Format specifies the ranage which can either be
%.. .. .. a character vector, eg, 'A23:F25', or
%.. .. .. a cell array containing one character vector, eg, {'A23:F25'}
%.. .. .. Note: to operate on an entire column (say, B) use 'B:B'
%.. .. format: 
%.. ..    '0'    no decimal places, no decimal point
%.. ..    '0.'   no decimal places, with decimal point
%.. ..    '0.0'  one decimal place
%.. .. there may be other format specifications that are valid that 
%.. .. control more sophisticated numnber formats.

if ~iscell(cellsToFormat)
    cellsToFormat = {cellsToFormat};
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);
theCell = thisSheet.Range(cellsToFormat{1});
theCell.NumberFormat = format;

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
