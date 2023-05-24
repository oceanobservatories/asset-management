function write_excel_doc_title(filename, docTitle)
%.. writes document title docTitle to excel file filename.
%
%.. filename and docTitle must be character vectors.
%.. filename must contain the full path of the excel filename

objExcel = actxserver('Excel.Application');
%.. filename must contain full path
workbookInterface = objExcel.Workbooks.Open(filename);
propertiesInterface = workbookInterface.BuiltinDocumentProperties;
titleInterface = get(propertiesInterface, 'Item', 'Title');
set(titleInterface, 'Value', docTitle);
%.. display updated title
title = get(titleInterface, 'Value');
%disp(' ');
disp(['    Title: ' title]);
%disp(' ');
%.. save change and clean up
workbookInterface.Save()
workbookInterface.Close()
objExcel.Quit();
objExcel.delete();  % lower case 'd'

clear objExcel workbookInterface propertiesInterface titleInterface

commandwindow