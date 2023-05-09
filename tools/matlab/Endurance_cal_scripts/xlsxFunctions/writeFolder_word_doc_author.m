function writeFolder_word_doc_author(docAuthor)
%.. writes docAuthor to the author property of all of the word documents
%.. found in the WORKING DIRECTORY.
%
%.. filename and docAuthor must be character vectors.
%.. filename must contain the full path of the word document

disp(['Working directory is :  ' pwd]);
wdir = pwd;
%.. make sure wdir terminates with a backslash.
%.. (pwd returns 'R:\Temp', but will also return 'R:\') 
wdir(end+1) = '\';
wdir = strrep(wdir, '\\', '\');

disp('Listing of all docx files whose author properties will be set:');
listing = sort(cellstr(ls('*.docx')));
disp(listing);
disp(' ');

listing = strcat(wdir, listing);
for ii = 1:numel(listing)
    filename = listing{ii};
    
    %.. this is the write_excel_doc_author.m function
    hdlActiveX = actxserver('Word.Application');
    %.. filename must contain full path
    hdlWordDoc = hdlActiveX.Documents.Open(filename);
    propertiesInterface = hdlWordDoc.BuiltinDocumentProperties;
    authorInterface = get(propertiesInterface, 'Item', 'Author');
    set(authorInterface, 'Value', docAuthor);
    %.. display updated title
    author = get(authorInterface, 'Value');
    %disp(' ');
    disp(['    Author: ' author]);
    %disp(' ');
    %.. save change and clean up
    hdlWordDoc.Save()
    hdlWordDoc.Close()
    hdlActiveX.Quit();
    hdlActiveX.delete();  % lower case 'd'
    
    clear hdlActiveX hdlWordDoc propertiesInterface authorInterface
    
end

commandwindow
