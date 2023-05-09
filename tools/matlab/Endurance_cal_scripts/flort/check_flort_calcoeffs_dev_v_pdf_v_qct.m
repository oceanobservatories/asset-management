function check_flort_calcoeffs_dev_v_pdf_v_qct
%.. desiderio 15-feb-2023 
%
%.. does a directory listing of the current working directory and
%.. opens pdf, qct, and dev files so that the calibration coefficients
%.. can be easily compared.
%
%.. IT IS REQUIRED THAT THE QCT HAS BEEN RENAMED TO INCLUDE THE 
%.. SERIAL NUMBER OF THE FLORT; THIS WILL BE SO IF THE PROGRAM 
%.. IMPORT_FLORT_CALFILES HAS BEEN RUN.

disp(' ')
disp(pwd)
disp(' ')
listing = sort(cellstr(ls('*.*')));

pdfFile = listing(contains(listing, '.pdf'));
disp('PDF file(s):')
disp(pdfFile)
qctFile = listing(contains(listing, '.log'));
disp(['QCT file: ' qctFile{1}])

devFile = listing(contains(listing, '.dev'));
%.. put this on screen before focus is lost ('notepad' system command)
disp(['dev file: ' devFile{1}])
type(devFile{1});
%.. pause so that dev file will type out to the command window BEFORE the
%.. system notepad command is executed which interrupts code execution.
pause(0.1)
%.. triplet pdf documentation can either be 1 pdf file with one
%.. page for each sensor or as 3 separate pdf files
for ii = 1:numel(pdfFile)
    open(pdfFile{ii});
end
    
system(['notepad ' qctFile{1}]);
