function write_word_doc_author(filename, docAuthor)
%.. writes docAuthor to the author property of the word document given by filename.
%
%.. filename and docAuthor must be character vectors.
%.. filename must contain the full path of the word document

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

clear hdlActiveX hdlWordDoc propertiesInterface titleInterface

commandwindow
