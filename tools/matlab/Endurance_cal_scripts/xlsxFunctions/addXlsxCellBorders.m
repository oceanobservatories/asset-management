function addXlsxCellBorders(xlsxName, sheetID, cellsToFormat, weight)
%.. desiderio 2019-08-31
%
%.. xlsxName [character vector] must contain the full path
%.. sheetID can either be the sheetName (character vector) or sheetNumber
%.. cells2Format can either be
%.. .. a character vector, eg, 'A23:A25', or
%.. .. a cell array of character vectors, eg, {'A23' 'A25' 'A43:A46'}
%
%.. borders of all the cells in the range are outlined.

%.. note that the border designations refer to the entirety of the 
%.. range of cells specified in cellsToFormat; that is, for a 5x5 matrix
%.. of excel cells, xlEdgeBottom outlines the lower boundary of the bottom
%.. 5 cells.

%.. weight is optional:

%.. border weights
%.. .. xlHairline  =  1
%.. .. xlThin      =  2
%.. .. xlMedium    =  -4138  % too bold for me
%.. .. xlThick     =  4

if nargin==3
    weight = 2;
end

borderPosition= {
    'xlEdgeBottom'
    'xlEdgeLeft'
    'xlEdgeRight'
    'xlEdgeTop'
    'xlInsideHorizontal'
    'XlInsideVertical'
    };

%.. there are also:
%..   xlDiagonalDown
%..   xlDiagonalUp

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
    for jj = 1:length(borderPosition)
        theCell.Borders.Item(borderPosition{jj}).LineStyle = 1;
        theCell.Borders.Item(borderPosition{jj}).Weight    = weight;
    end
end

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
