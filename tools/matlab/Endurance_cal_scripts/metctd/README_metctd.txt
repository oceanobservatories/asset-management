readme: metctd

write_metctd_calcoeffs_to_csv('metctd_sn10906_qct00174.log')
                         OR  
write_metctd_calcoeffs_to_csv('10906.cal')



There are a lot of files here because the consistency checker 
compare_metctd_calcoeffs.m (REQUIRES TEXT ANALYTICS TOOLBOX)
uses them:

function compare_metctd_calcoeffs
%.. the working directory must contain the vendor documentation
%.. containing the calcoeffs to be compared:
%..     T and C pdfs, QCT cap, cal.
%
%.. OUTPUTS EACH CALCOEFF FROM THESE 3 SOURCES TO THE MATLAB COMMAND WINDOW
%.. FOR EASE OF COMPARISON.
%
% pdf; qct; cal:
%
% A0
% -7.128462e-005  (T pdf)
% -7.128463e-05     (qct)
% -7.128462e-005    (cal)
%
%.. DEPENDENCES:
%.. .. rad_read_metctd_cal.m
%.. .. rad_read_metctd_cap.m
%.. .. rad_read_metctd_Cpdf.m      REQUIRES TEXT ANALYTICS TOOLBOX
%.. .. rad_read_metctd_Tpdf.m      REQUIRES TEXT ANALYTICS TOOLBOX
%.. .. merge_metctd_TandC_calStructs.m
%
%.. note that the program rename_metctd_qctlog.m will have been run to 
%.. process the raw qct logs downloaded from Vault, so that the form of 
%.. qct filenames is: metctd_sn11000_qct00129_20190704.log.

