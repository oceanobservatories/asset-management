readme: presf

write_presf_qct_to_csv('3305-00105-00106.cap')

cd compareFiles
file1 = 'CGINS-PRESFB-01397__20191216.csv';
file2 = 'CGINS-PRESFB-01397__20211114.csv';
comparePRESFcsvCalfiles(file1, file2);