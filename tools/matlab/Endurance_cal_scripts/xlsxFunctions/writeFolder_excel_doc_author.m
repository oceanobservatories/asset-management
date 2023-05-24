function writeFolder_excel_doc_author(docAuthor)
%.. writes docAuthor to the author property of all of the excel files
%.. found in the WORKING DIRECTORY.
%
%.. filename and docAuthor must be character vectors.
%.. filename must contain the full path of the excel spreadsheet

disp(['Working directory is :  ' pwd]);
wdir = pwd;
%.. make sure wdir terminates with a backslash.
%.. (pwd returns 'R:\Temp', but will also return 'R:\') 
wdir(end+1) = '\';
wdir = strrep(wdir, '\\', '\');

disp('Listing of all xlsx files whose author properties will be set:');
listing = sort(cellstr(ls('*.xlsx')));
disp(listing);
disp(' ');

listing = strcat(wdir, listing);
for ii = 1:numel(listing)
    filename = listing{ii};
    
    %.. this is the write_excel_doc_author.m function
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
    clear objExcel workbookInterface propertiesInterface authorInterface
    
end

commandwindow