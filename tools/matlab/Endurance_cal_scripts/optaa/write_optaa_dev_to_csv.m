function [csvfilename, taarray_filename, tcarray_filename] = ...
          write_optaa_dev_to_csv(devfilename)
%.. desiderio 31-mar-2017
%
%.. reads in the WETLabs dev file devfilename and writes out the
%.. calcoeffs needed for the CI calibration sheets to a 
%.. csv file to be uploaded to asset management on GitHub.
%
%.. adapted from write_acs_devfile_to_xlsx:
%.. .. writing out main file should be straightforward
%.. .. use csvwrite to write out temp compensation values 
%
%.. FUNCTION CALLS:
%.. dev = rad_read_acs_devfile(devfilename)
%
%.. desiderio 05-feb-2021: added SN 315 and 344 ("D" series)

%.. always best to clear cell arrays at program top during development
clear template

% cd R:
% cd ..

%.. lookup tables for series as a function of serial number
seriesC = [140 142 249 266];
seriesD = [124 127 135 136 149 ...
           154 169 170 171 174 ...
           179 182 183 184 191 ...
           208 214 221 258 259 ...
           260 261 267 315 344    ];
seriesJ = [137 138 139 168 283 284];
    
caldate_provenance = ['date in filename comes from ''offsets saved'' ' ...
    'date within factory devfile'];

dev = rad_read_acs_devfile(devfilename);
%.. find series based on serial number
if ismember(dev.sernum, seriesC)
    series = 'C';
elseif ismember(dev.sernum, seriesD)
    series = 'D';
elseif ismember(dev.sernum, seriesJ)
    series = 'J';
else
    error('OPTAA Series cannot be determined from serial number.');
end
sernum = num2str(dev.sernum);  % string

caldate = dev.date;
caldate([5,8]) = [];  % remove underscores in date

%.. construct filenames
basename = ['CGINS-OPTAA' series '-00' sernum '__' caldate];
csvfilename = [basename '.csv'];
taarray_filename = [basename '__CC_taarray.ext'];
tcarray_filename = [basename '__CC_tcarray.ext'];

%.. initialize cell array of strings
template(1:8, 1:4) = {''};
%.. serial number and coeff names to be written out
template(1:8, 1) = {['ACS-' sernum]};  % 1st character of string is '
template(1:8, 2) = {'CC_cwlngth', 'CC_ccwo', 'CC_tcal', 'CC_tbins', ...
                    'CC_awlngth', 'CC_acwo', 'CC_taarray', 'CC_tcarray'};

%.. coeff values to be written out
%.. on github, an entry of an array is enclosed in double quotes.
%.. for vectors written in JSON format, the sprintf statements terminate
%.. in ' ..., numx, numy, numz, ]' so that the penultimate 2 characters
%.. need to be deleted.
%
% 'c' wavelengths
template{1, 3} = ['"[' sprintf('%.1f, ', dev.cwvl) ']"'];
template{1, 3}(end-3:end-2) = [];  % delete last ', ' 
% 'c' offsets
template{2, 3} = ['"[' sprintf('%.6f, ', dev.coff) ']"'];
template{2, 3}(end-3:end-2) = []; 
% factory cal water temperature
template{3, 3} = sprintf('%.1f', dev.tcal); 
% internal temperature compensation bin values
template{4, 3} = ['"[' sprintf('%.6f, ', dev.tbin) ']"'];
template{4, 3}(end-3:end-2) = []; 
% 'a' wavelengths
template{5, 3} = ['"[' sprintf('%.1f, ', dev.awvl) ']"'];
template{5, 3}(end-3:end-2) = []; 
% 'a' offsets
template{6, 3} = ['"[' sprintf('%.6f, ', dev.aoff) ']"'];
template{6, 3}(end-3:end-2) = []; 
% sheetname reference for taarray
template{7, 3} = 'SheetRef:CC_taarray';
% sheetname reference for tcarray
template{8, 3} = 'SheetRef:CC_tcarray';

%.. add caldate provenance to the Tcal row
template(3,4) = {caldate_provenance};

% %.. REORDER rows to match current entries in GitHub repository
% template = template([6 5 2 1 7 4 3 8], :);

%.. REORDER rows 
template = template([3 5 6 1 2 4 7 8], :);

%.. write directly out to a text file, no xlsx in-between.
header = 'serial,name,value,notes';  %  'notes' is the 4th column
fid = fopen(csvfilename, 'w');
fprintf(fid, '%s\r\n', header);
for ii = 1:length(template)
    fprintf(fid, '%s,%s,%s,%s\r\n', template{ii, :});
end
fclose(fid);

%.. WRITING OUT TEMPERATURE COMPENSATION COEFFICIENTS
%.. csvwrite writes to 5 signficant figures, which is adequate. It also
%.. terminates lines in a LF with no CR. I anticipate that the csv-
%.. written files will upload as expected to the GitHub repository.
%.. However, when viewing in the Windows environment of my local master,
%.. use wordpad and not notepad to inspect. Notepad will not display an
%.. an accurate count of the number of rows in the file.

%.. write out abs channel temp comp coeffs
csvwrite(taarray_filename, dev.atbin);
%.. write out beamc channel temp comp coeffs.
csvwrite(tcarray_filename, dev.ctbin);

end
