function write_excel_doc_author(filename, docAuthor)
%.. writes docAuthor to the author property of the excel file given by filename.
%
%.. filename and docAuthor must be character vectors.
%.. filename must contain the full path of the excel spreadsheet

objExcel = actxserver('Excel.Application');
%.. filename must contain full path
workbookInterface = objExcel.Workbooks.Open(filename);
propertiesInterface = workbookInterface.BuiltinDocumentProperties;
authorInterface = get(propertiesInterface, 'Item', 'Author');
set(authorInterface, 'Value', docAuthor);
%.. display updated title
author = get(authorInterface, 'Value');
%disp(' ');
disp(['    Author: ' author]);
%disp(' ');
%.. save change and clean up
workbookInterface.Save()
workbookInterface.Close()
objExcel.Quit();
objExcel.delete();  % lower case 'd'

clear objExcel workbookInterface propertiesInterface titleInterface

commandwindow