function horzAlignXlsxText(xlsxName, sheetID, cellsToFormat, position)
%.. desiderio 2019-04-24
%
%.. changes the horizontal alignment of text in a range of excel cells.
%.. .. xlsxName [character vector] must contain the full path
%.. .. sheetID can either be the sheetName (character vector) or sheetNumber
%.. .. cells2Format specifies the ranage which can either be
%.. .. .. a character vector, eg, 'A23:F25', or
%.. .. .. a cell array containing one character vector, eg, {'A23:F25'}
%.. .. .. Note: to operate on an entire column (say, B) use 'B:B'
%.. .. position must be either 'left', 'center', or 'right'

if ~iscell(cellsToFormat)
    cellsToFormat = {cellsToFormat};
end

if strcmpi(position,     'left')
    position = -4131;
elseif strcmpi(position, 'center')
    position = -4108;
elseif strcmpi(position, 'right')
    position = -4152;
else
    error(' position value must be one of ''left'', ''center'', or ''right'' ');
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);
theCell = thisSheet.Range(cellsToFormat{1});
theCell.HorizontalAlignment = position;

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
