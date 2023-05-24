function colorXlsxCells(xlsxName, sheetID, cellsToFormat, color)
%.. desiderio 2019-04-19
%
%        CAN WORK WITH EITHER COLORINDEX OR RGB COLOR DESIGNATIONS
%
%.. xlsxName [character vector] must contain the full path
%.. sheetID can either be the sheetName (character vector) or sheetNumber
%.. cells2Format can either be
%.. .. a character vector, eg, 'A23:A25', or
%.. .. a cell array of character vectors, eg, {'A23' 'A25' 'A43:A46'}
%.. color is an integer which denotes both the color table and color:
%.. .. if color is a negative integer it denotes the ColorIndex color system,
%.. .. which assigns 56 pre-defined colors to integers from [1:56]; therefore
%.. .. the calling argument must be one of the integers -1:-56.
%.. ..
%.. .. if color is a positive integer the RGB system is used, where each
%.. .. R,G,B component can take on a value of 0:255. an example follows.
%
%.. in the ColorIndex system, color 39 is an Easter egg lavender color:
%.. ..      use color = -39 as a calling argument.
%.. in the RGB system, this color is (204, 153, 255) == (CC, 99, FF);
%.. ..      to get the correct color the 'RGB' must be flipped to 'BGR':
%.. ..      use color = hex2dec('FF99CC') as a calling argument.
%
%
%>> Diagnostic Note:
%.. .. if the fill color is unexpectedly black, it could be that the intent
%.. .. was to use the colorIndex system, but the calling argument used was
%.. .. positive instead of negative; all values [1:56] will give what 
%.. .. appears to be black in the RGB system.


if ~iscell(cellsToFormat)
    cellsToFormat = {cellsToFormat};
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);

if color < 0
    colorIndex = -color;
    for ii = 1:length(cellsToFormat)
        theCell = thisSheet.Range(cellsToFormat{ii});
        theCell.Interior.ColorIndex = colorIndex;
    end
else
    for ii = 1:length(cellsToFormat)
        theCell = thisSheet.Range(cellsToFormat{ii});
        theCell.Interior.Color = color;
    end
end

Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
