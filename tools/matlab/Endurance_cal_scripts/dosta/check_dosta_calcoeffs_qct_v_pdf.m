function check_dosta_calcoeffs_qct_v_pdf
%.. desiderio 15-feb-2023 
%
%.. does a directory listing of the current working directory and
%.. opens dosta pdf calibration certificates and their corresponding
%.. QCTs so that the calibration coefficients can be easily compared.
%
%.. IT IS REQUIRED THAT THE QCT HAS BEEN RENAMED TO INCLUDE THE 
%.. SERIAL NUMBER OF THE DOSTA IN THE SAME MANNER AS IS USED IN
%.. THE PDF FILENAME; THIS WILL BE SO IF THE PROGRAM IMPORT_DOSTA_CALFILES
%.. HAS BEEN RUN.

%.. do in serial number order
listingPDF = sort(cellstr(ls('*.pdf')));  % SN order
listingQCT = sort(cellstr(ls('*.log')));  % qct sequence order

%.. opening the QCT in notepad results in an automatic pause; dismiss
%.. the notepad window to go to the next iteration.
for ii=1:numel(listingPDF)
    open(listingPDF{ii});
    tok = strsplit(listingPDF{ii}, '_');
    idx = find(contains(tok, 'SN'));
    match = [tok{idx} '_' tok{idx+1}];
    qctFile = listingQCT(contains(listingQCT, match));
    system(['notepad ' qctFile{1}]);
end
