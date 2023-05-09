function setXlsxFontStyle(xlsxName, sheetID, cellsToFormat, fontStyle, tf)
%.. desiderio 2019-04-12
%
%.. xlsxName [character vector] must contain the full path
%.. sheetID can either be the sheetName (character vector) or sheetNumber
%.. cells2Format can either be
%.. .. a character vector, eg, 'A23:A25', or
%.. .. a cell array of character vectors, eg, {'A23' 'A25' 'A43:A46'}
%.. fontStyle must be either 'Bold' or 'Italic'
%.. tf must be a logical variable, either true or false
%
%.. to set the font to italic and bold, call twice, once for each fontStyle
%.. (both calls with tf set to true).
%
%.. to set back to regular font, call twice, with tf = false.

if ~iscell(cellsToFormat)
    cellsToFormat = {cellsToFormat};
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);

for ii = 1:length(cellsToFormat)
    theCell = thisSheet.Range(cellsToFormat{ii});
    set(theCell.Font, fontStyle, tf);
end

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
