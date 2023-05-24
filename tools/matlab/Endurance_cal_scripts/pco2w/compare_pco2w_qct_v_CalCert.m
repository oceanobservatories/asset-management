function compare_pco2w_qct_v_CalCert
%.. desiderio 16-feb-2023 initial code
%
%.. facilitates comparison of pco2w calcoeffs by stepping through
%.. serial numbers being deployed and opening the pdf and qct log file
%.. for simultaneous viewing. Also, if the qct filenames contain 'yyyymmdd'
%.. then they will be duplicated by being copied to the staging folder with
%.. a new filename: the caldate in the ValCert filename will be copied over
%.. into the new QCT filename replacing the 'yyyymmdd'.
%..
%.. Once it is verified that there are no surprises, the original qct files
%.. with 'yyyymmdd' in their filenames can be deleted by hand.
%
%.. This code will still also run after the above deletions by hand have 
%.. been executed: no file copying is done, but the qct files and pdf files
%.. will still be opened up on the monitor for calcoeff comparision.
%
%.. Filename formats:
%.. .. QCT:       3305-00110-00253_SN_C0061_yyyymmdd.log (before file copy)
%.. .. CalCert:   C0061_CalCert_20230201.pdf
%..
%.. .. QCT:       3305-00110-00253_SN_C0061_20230201.log (after file copy)
%
%.. Normally the 2 substrate filetypes can be generated from zip files 
%.. downloaded from Vault and running these scripts:
%.. .. extractAndRenamePCO2Wqcts.m
%.. .. extractAndRenamePCO2WcalCerts.m
%
%.. Therefore it is expected that there is a 1:1 correspondence between
%.. the number of qctfiles and the number of calcerts.

%.. set staging folder to the folder containing all of these files
%staging = 'K:\staging\pco2w';
%cd(staging)

qctFile = sort(cellstr(ls('3305*')));
pdfFile = sort(cellstr(ls('*.pdf')));

%.. as before opening notepad effects a system pause while the notepad
%.. window remains open. closing it will initiate continuation of the loop.
%.. succeeding pdf files will open in new windows in the one acrobat
%.. instantiation.
firstRun = false;
for ii = 1:numel(pdfFile)
    disp(num2str(ii));
    serialNumber = pdfFile{ii}(1:5);
    calDate      = pdfFile{ii}(15:22);
    idx          = find(contains(qctFile, serialNumber));
    qctfileName  = qctFile{idx};
    if contains(qctfileName, 'yyyymmdd')
        firstRun = true;
        qctfileName = strrep(qctfileName, 'yyyymmdd', calDate);
        copyfile(fullfile(staging, qctFile{idx}), fullfile(staging, qctfileName))
        disp(['OldName: ' qctFile{idx}]);
    end
    disp(['QCTname: ' qctfileName]);
    open(pdfFile{ii});
    system(['notepad ' qctfileName]);
    %.. execution will pause here until notepad window is dismissed
end

if firstRun
    fprintf('\n\n');
    endingMessage = ['Compare the old and newly named QCT files in the ' ...
        'staging area and delete the old ones if satisfied.'];
    disp(endingMessage);
end

