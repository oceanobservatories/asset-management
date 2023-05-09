function [cal] = rad_read_metctd_Cpdf(pdfFile)
%.. desiderio 31-jan-2023: read SBE sbe37 C calfile pdf and output
%..                        calcoeffs and meta data in a structure.
%
%.. pdf must include the full path of this infile unless
%.. the file is located in the working directory.

%.. including both C and T calcoeff fields will make blending the C and T
%.. data structures into one later in the processing.
calFields = {
    'sernum'
    'caldate_temperature'
    'caldate_conductivity'
    'A0'
    'A1'
    'A2'
    'A3'
    'G'
    'H'
    'I'
    'J'
    'CPCOR'
    'CTCOR'
    'WBOTC'
    };

%.. initialize; only the sernum and C info can be entered.
for ii = 1:numel(calFields)
    cal.(calFields{ii}) = '';
end

%.. Conductivity calcoeff names
coeff_name = {
    'G' 'H' 'I' 'J'               ...
    'CPCOR' 'CTCOR' 'WBOTC'       ...
    };

C = extractFileText(pdfFile);
C = strtrim(strsplit(C, '\n'))';

%.. parse serial number into cal data structure.
sss = C(contains(C, 'SENSOR SERIAL NUMBER:'));
if isempty(sss)
    error('Could not find serial number');
end
%.. read serial number from characters after colon 
toks = strsplit(sss);
cal.sernum = num2str(toks(end), '%5.5u');

%.. find the sensor caldate
sss = C(contains(C, 'CALIBRATION DATE:'));
if isempty(sss)
    error('Could not find calibration date');
end
%.. read caldate from characters after colon 
toks = strsplit(sss);
sss  = char(toks(end));
if numel(sss)==8
    disp('warning: there may have been a leading 0 missing from the date day.')
    sss = ['0' sss];
end
cal.caldate_conductivity = sss;

%.. populate the structure fields.
%.. snip out just the cal coefficient section
idx_coeffs = find(contains(C, 'COEFFICIENTS:'));
Coeff = C(idx_coeffs+1:idx_coeffs+7);
for ii=1:length(coeff_name)
    sss = Coeff(contains(Coeff, coeff_name{ii}, 'IgnoreCase', true));
    if isempty(sss)
        error('No CONDUCTIVITY coefficients found.')
    end
    toks = strsplit(sss);
    cal.(coeff_name{ii}) = char(toks(end));
end
    
end
