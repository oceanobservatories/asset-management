readme: presf

write_presf_qct_to_csv('3305-00105-00106.cap')


function comparePRESFcsvCalfiles(file1, file2)
%.. accepts two calling arguments each naming an OOI
%.. csv calfile from the same SBE26P (PRESF) sensor
%.. and compares their cal coeffs; these are 
%.. for pressure and usually (never?) change,
%.. except for a particular OFFSET 

file1 = 'CGINS-PRESFB-01397__20191216.csv';
file2 = 'CGINS-PRESFB-01397__20211114.csv';
comparePRESFcsvCalfiles(file1, file2);
