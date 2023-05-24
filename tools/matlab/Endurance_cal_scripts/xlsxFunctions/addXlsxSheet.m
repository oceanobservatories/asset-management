function addXlsxSheet(xlsxName, sheetName, position)
%.. desiderio 2019-08-31
%
%.. xlsxName [character vector] must contain the full path.
%.. sheetname must be a character vector.
%..
%.. position is either:
%.. .. an integer denoting the placement of the new sheet;
%.. ..    1 for the first sheet in the workbook, 2 for the second, etc.
%.. .. 'last'

% Calling argument list for the 'Add' method:
% expression.Add(beforeItem, afterItem, numberSheetsToAdd, sheetType)

if ischar(position)
    if contains(lower(position), {'end' 'last'})
        addMode = 'last';
    else
        error('3rd calling argument invalid');
    end
else
    if ~isnumeric(position)
        error('3rd calling argument invalid');
    else 
        addMode = 'beforeItem';
    end
end

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
WB = Workbooks.Open(xlsxName);
WS = WB.Worksheets;

if strcmp(addMode, 'last')
    WS.Add([], WS.Item(WS.Count)).Name = sheetName;
elseif strcmp(addMode, 'beforeItem')
    WS.Add(WS.Item(position)).Name = sheetName;
else
    error('illegal value for ''addMode'' switch')
end

WB.Save();
WB.Close();
Excel.Quit();
Excel.delete();
