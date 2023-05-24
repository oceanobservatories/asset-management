function copyXlsxSheetToWorkbook(sourceName,      sourceSheetID, ...
                                 destinationName, destinationSheetName)
%.. desiderio 2019-10-01
%
%.. sourceName and destinationName [character vectors] must contain full path
%.. sourceSheetID can either be the sheetName (character vector) or sheetNumber
%.. destinationSheetName must be a character vector
%
%.. if the destinationName excel file does not exist, it will be created.
%
%.. 1st attempt, always copy source sheet before the 1st sheet in destination.

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
wbsource      = Workbooks.Open(sourceName);
ws = wbsource.Worksheets.Item(sourceSheetID);
%.. change the name of the ws object.
%.. .. note that in doing this, if wbsource is saved as is, the source sheet
%.. .. in the source xlsx file will also be renamed to destinationSheetName.
ws.Name = destinationSheetName;
%.. if destination xlsx file doesn't exist, create and name it.
if ~exist(destinationName, 'file')
    wbdestination = Workbooks.Add;
    SaveAs(wbdestination, destinationName)
else
    wbdestination = Workbooks.Open(destinationName);
end

%.. copy the sheet to the destination excel workbook before its 1st sheet.
ws.Copy(wbdestination.Worksheets.Item(1));
%.. save and close the destination workbook
wbdestination.Save
wbdestination.Close();
%.. to close the source workbook without saving changes and without activating
%.. the 'saving changes' prompt, set DisplayAlerts to false.
Excel.DisplayAlerts = 0;
wbsource.Close  % no prompt and changes are not saved.
%
Excel.Quit();
Excel.delete();
