function csvfilename = write_presf_qct_to_csv(txtfilename)
%.. desiderio 01-apr-2017
%.. desiderio 20-mar-2018  added subroutine to parse inconsistent 
%..                        date fields.
%
%.. reads in calcoeffs from Seabird 26+ text files and writes out the
%.. calcoeffs into a csv file for uploading to GitHub. Input files
%.. can either be 'cap' (captured) files from a QCT or hex files
%.. (because the calcoeffs in both are listed in the same way
%.. enabling a common read mechanism).
%
%.. note that the pressure offset adjustment value is normally not in
%.. the *.cal or *.psa file, rather a vendor pdf file is dedicated to 
%.. reporting this value. also, the slope value when these instruments
%.. come back from refurb is always 1. The QCT is always current on
%.. the cal coeff values.
%
%.. filename must include the full path of the infile unless
%.. the file is located in the working directory.
%
%.. FUNCTION CALLS:
%.. [cal] = rad_read_presf_cap(txtfilename)

clearvars template C

seriesA = [1328 1351 1382 1383 1391];
seriesB = [1384 1396 1397];
seriesC = [1385 1398 1399];

caldate_provenance = ['date in filename comes from latest ' ...
       'sensor caldate read from file captured from relevant QCT'];

cal = rad_read_presf_cap(txtfilename);

%.. find latest sensor caldate to use in outputfilename
cdate{1} = parse_date(cal.Tcal);
cdate{2} = parse_date(cal.Pcal);
cdate = sort(cdate);
cdate = cdate{end};

%.. also turn serial number (without model number) 
%.. into a 5 character string for output filename
sernum_5char = num2str(cal.sernum, '%5.5u');

%.. find series based on serial number
if ismember(cal.sernum, seriesA)
    series = 'A';
elseif ismember(cal.sernum, seriesB)
    series = 'B';
elseif ismember(cal.sernum, seriesC)
    series = 'C';
else
    error('PRESF Series cannot be determined from serial number.');
end

%.. construct output filename
csvfilename = ['CGINS-PRESF' series '-' sernum_5char '__' cdate '.csv'];
    
nrows= 22;  % number of calcoeff lines to be exported

%.. serial number to be written out.
%.. instead of 26-0XXXX, I've switched to 26P-XXXX
template(1:nrows, 1) = {['26P-' num2str(cal.sernum)]};
%.. omaha coeff names
fnames = lower(fieldnames(cal));  % lower case
fnames(1:3) = [];  % delete serial number and caldate fieldnames
%.. the cap fieldnames now differ from the Omaha calsheet entries
%.. in three ways:
%..    (1) the (original) Omaha sheets omitted the temperature coeffs.
%..    (2) there are two extra entries in the Omaha sheet.
%..    (3) the OFFSET calcoeff is given a different name.
%.. the cap structure includes the 4 temperature calcoeffs at the end.
%
%.. construct the Omaha calcoeff names from the fieldnames.
calcoeff_names = cellfun(@(x) ['CC_' x], fnames, 'UniformOutput', 0);
%.. populate the template entries to be written out.
template(1:5, 2) = calcoeff_names(1:5);
template(6, 2) = {'CC_offset_correction_factor'};
template(7, 2) = {'CC_pressure_offset_calibration_coefficient'};
template(8, 2) = {'CC_slope_correction_factor'};
%.. calcoeff_names #6 was renamed on output as template(7,2) above
template(9:22, 2) = calcoeff_names(7:20);

%.. coeff values to be written out; isomorphic with above section
C = struct2cell(cal);
C(1:3) = [];
template(1:5, 3) = C(1:5);
template(6, 3) = {'0'};  % seems to be a default value
template(7, 3) = C(6);
template(8, 3) = {'1'};  % seems to be a default value
template(9:22, 3) = C(7:20);

%.. the temperature coefficients are not used; these are the
%.. the last 4 fields, so get rid of them.
template(end-3:end, :) = [];

%.. alphabetically reorder coeffs to match what is already on github
template = template([17 1:5 18 6:16], :);

%.. add caldate provenance
template(1,4) = {caldate_provenance};

%.. write directly out to a text file, no xlsx in-between.
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';  %  'notes' is the 4th column
fprintf(fid, '%s\n', header);
%.. first template line has 4 arguments
fprintf(fid, '%s,%s,%s,%s\n', template{1, 1:4});
%.. append a comma to each line to denote an empty 4th column.
for ii = 2:length(template)
    fprintf(fid, '%s,%s,%s,\n', template{ii, 1:3});
end
fclose(fid);

%.. for comparison with OOI csv file, need to add two fields:
cal.offsetFactor = '0';
cal.slopeFactor  = '1';
P = [1:3 18 4:8 19 24 9 25 10:17 20:23];
disp(orderfields(cal, P));

%.. calling notepad using system results in putting matlab in "pause";
%.. closing the notepad window will resume execution. therefore using
%.. notepad to open both files can using system calls can only display
%.. one file at a time. However, this is not how Wordpad acts, so
system(['C:\Windows\System32\write.exe ' txtfilename]);
system(['notepad ' csvfilename]);

end

function date_char = parse_date(str)
%.. the dates output by the SBE26P instruments in the QCTs
%.. (and in their hex files) have a variety of formats - even
%.. within the same file:
%
%   9-nov-16
%   09-nov-2016
%   11-09-2016
%
%.. date_char for any of the inputs above will be '20161109'.

%.. the only commonality is that the delimiter is a hyphen. So.

if ~contains(str, '-')
    disp(['sensor date is ' str]);
    error('PRESF sensordates inside qct files no longer contain hyphens.');
end

months = {'jan', 'feb', 'mar', 'apr', 'may', 'jun', ...
          'jul', 'aug', 'sep', 'oct', 'nov', 'dec'};

D = textscan(str, '%s', 'delimiter', '-');
D = D{1};
%.. parse middle characters to differentiate cases
mid = strtrim(D{2});
if all(isletter(mid))
    mm = find(strcmpi(months, mid));
    mm = num2str(mm, '%2.2u');
    dd = strtrim(D{1});
    nchar = length(dd);
    if nchar == 1
        dd = ['0' dd];
    elseif nchar == 2
        %.. already OK
    else
        disp(['sensor date is ' str]);
        error('Unparseable presf sensor caldate inside cap file.');
    end
elseif all(~isletter(mid))  %  no letters, so month then day then year
    mm = num2str( str2num(D{1}), '%2.2u');  %#ok
    dd = num2str( str2num(mid), '%2.2u');   %#ok
else
    disp(['sensor date is ' str]);
    error('Unparseable presf sensor caldate inside cap file.');
end
%.. parse year
yyyy = strtrim(D{3});
nchar = length(yyyy);
if nchar == 2
    yyyy = ['20' yyyy];
elseif nchar == 4
    %.. already OK
else
    disp(['sensor date is ' str]);
    error('Unparseable presf sensor caldate inside cap file.');
end

date_char = [yyyy mm dd];

end
