function formatXlsxFont(xlsxName, sheetID, cellsToFormat, fontType, fontSize)
%.. desiderio 2019-04-12
%
%.. written to change the font of the comment sections in acs logfiles to
%.. to the monospaced font Consolas 9.
%.. .. xlsxName [character vector] must contain the full path
%.. .. sheetID can either be the sheetName (character vector) or sheetNumber
%.. .. cells2Format can either be
%.. .. .. a character vector, eg, 'A23:A25', or
%.. .. .. a cell array of character vectors, eg, {'A23' 'A25' 'A43:A46'}
%.. .. fontType must be a character vector (eg, 'Consolas')
%.. .. fontSize must be an integer that is supported as a size to fontType

if ~iscell(cellsToFormat)
    cellsToFormat = {cellsToFormat};
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);

disp(['Changing font of selected cells in sheet ' thisSheet.Name ...
    ' to ' fontType '.']);

for ii = 1:length(cellsToFormat)
    theCell = thisSheet.Range(cellsToFormat{ii});
    theCell.Font.Name = fontType;
    theCell.Font.Size = fontSize;
end

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
