function csvfilename = write_spkir_cal_to_csv(calfilename)
%.. desiderio 01-apr-2017
%
%.. reads in the Satlantic calfile information for OCR-507 downwelling
%.. irradiance instruments (SPKIR is the OOI designation) and writes
%.. out the calcoeffs as text arrays in JSON format for upload into
%.. the appropriate folder in the calibration GitHub repository.
%
%.. FUNCTION CALLS:
%.. [cal] = rad_read_spkir_cal(calfilename)
%
%.. desiderio 24-aug-2021: added screen output at end

clear template

seriesB = [231 232 242 243 248:250 254 255 294:298]; 
seriesJ = [237 252 264 266 281 282];

[~, name, ext] = fileparts(calfilename);
caldate_provenance = ['date in filename comes from latest caldate ' ...
    'within factory calfile ' name ext];

cal = rad_read_spkir_cal(calfilename);

%.. find series based on serial number
if ismember(cal.sernum, seriesB)
    series = 'B';
elseif ismember(cal.sernum, seriesJ)
    series = 'J';
else
    error('SPKIR Series cannot be determined from serial number.');
end

sn_str = num2str(cal.sernum);
date_str = cal.date;
date_str([5 8]) = [];  % delete '-'
%.. construct output filename
csvfilename = ['CGINS-SPKIR' series '-00' sn_str '__' date_str '.csv'];
%.. serial number to be written out
template(1:3, 1) = {cal.sernum};
%.. omaha coeff names
fnames = fieldnames(cal);
fnames([1 2 6]) = [];  % delete serial number, wavelength, and date fieldnames
template(1:3, 2) = cellfun(@(x) ['CC_' x], lower(fnames), ...
    'UniformOutput', 0);
%.. coeff arrays in JSON format
for ii=1:3
    %.. trailing zeroes are missing from calcoeffs from Satlantic ...
    %.. instead of transposing for sscanf: 
    str = '[';
    for jj=1:7
        str = [str cal.(fnames{ii}){jj} ', '];
    end
    str(end-1:end) = [];
    template{ii,3} = [str ']'];
end

%.. add caldate provenance
template(1,4) = {caldate_provenance};

%.. write directly out to a text file, no xlsx in-between.
header = 'serial,name,value,notes';  %  'notes' is the 4th column
fid = fopen(csvfilename, 'w');
fprintf(fid, '%s\r\n', header);
fprintf(fid, '%i,%s,"%s",%s\r\n', template{1,1:4});
%.. append a comma to each line to denote an empty 4th column.
%.. on github, an entry of an array is enclosed in double quotes.
for ii = 2:3
    fprintf(fid, '%i,%s,"%s",\r\n', template{ii,1:3});
end
fclose(fid);

%. for output to screen to check OOI calfile coeffs in export code ...
cal.date = {cal.date};  % so that transpose doesn't convert date to column vector
disp(structfun(@transpose, cal, 'uni', 0));

end
