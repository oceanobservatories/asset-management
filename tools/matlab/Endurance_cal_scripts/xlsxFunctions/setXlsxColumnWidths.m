function setXlsxColumnWidths(xlsxName, sheetID, columnsToFormat, columnWidths)
%.. desiderio 2019-04-19
%
%.. xlsxName [character vector] must contain the full path
%.. sheetID can either be the sheetName (character vector) or sheetNumber
%.. columnsToFormat must be a vector of positive integers
%.. columnWidths must be a vector of width sizes in a one-to-one 
%.. .. correspondence with the entries in columnsToFormat

if length(columnsToFormat) ~= length(columnWidths)
    error('columnsToFormat and columnWidths must have the same length.');
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);

for ii = 1:length(columnsToFormat)
    thisSheet.Columns.Item(columnsToFormat(ii)).columnWidth = columnWidths(ii);
end

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
