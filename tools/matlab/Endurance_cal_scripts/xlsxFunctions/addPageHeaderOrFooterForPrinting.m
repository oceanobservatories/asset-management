function addPageHeaderOrFooterForPrinting(xlsxName, sheetID, text, location)
%.. desiderio 2019-10-07
%
%.. xlsxName [character vector] must contain the full path
%.. sheetID can either be the sheetName (character vector) or sheetNumber
%.. text (character vector, string will probably work) to become header(footer)
%.. location: one of the 6 used in the conditional block, case insensitive 

Excel = actxserver('Excel.Application');  % Excel object
Workbooks = Excel.Workbooks;
Workbook = Workbooks.Open(xlsxName);
worksheets = Excel.sheets;
thisSheet = get(worksheets, 'Item', sheetID);
if     strcmpi(location, 'leftheader')
    thisSheet.PageSetup.LeftHeader = text;
elseif strcmpi(location, 'centerheader')
    thisSheet.PageSetup.CenterHeader = text;
elseif strcmpi(location, 'rightheader')
    thisSheet.PageSetup.RightHeader = text;
elseif strcmpi(location, 'leftfooter')
    thisSheet.PageSetup.LeftFooter = text;
elseif strcmpi(location, 'centerfooter')
    thisSheet.PageSetup.CenterFooter = text;
elseif strcmpi(location, 'rightfooter')
    thisSheet.PageSetup.RightFooter = text;
else
    disp('Warning: header or footer location not recognized.');
end
Workbook.Save();
Workbook.Close();
Excel.Quit();
Excel.delete();
