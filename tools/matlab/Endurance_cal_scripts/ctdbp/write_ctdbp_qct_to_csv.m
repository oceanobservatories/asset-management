function csvfilename = write_ctdbp_qct_to_csv(capfilename)
%.. desiderio 30-sep-2017 
%.. .. modification of write_ctdbp_xmlcon_to_csv.m to operate on a cap
%.. ..        file instead of an xmlcon file by calling the appropriate
%.. ..        subroutine to read in the cap file data into a structure.
%.. .. the cal information in the SBE16+ hex file header is in an xml
%.. ..        format, so that if calcoeffs are to be read from a hex
%.. ..        file, the script write_ctdbp_xmlcon_to_csv.m may work.
%.. ..
%.. .. write_ctdbp_cap_to_csv was coded because WHOI and UW have observed
%.. ..        that the SBE-supplied pdf calfiles are sometimes not 
%.. ..        current with respect to the data in the CTD's firmware.
%.. desiderio 01-apr-2017
%.. desiderio 27-jul-2020 re-orients fields at end for on-screen checks
%
%.. reads in the SBE cap file information from a QCT and writes out
%.. the calcoeffs into csv files for uploading to the appropriate
%.. calibration folders in the github repository.
%
%.. as opposed to when the transferrance of calcoeffs was accomplished
%.. by pasting them into an excel Omaha sheet, the method in this
%.. program reads in the coeffs from the cap file as ascii and
%.. writes them out as ascii; no sigfig problem.
%
%.. FUNCTION CALLS:
%.. [con] = rad_read_ctdbp_cap(capfilename)

clear template C con sernum_5char

seriesC = [7240:7243 50006 50007 50009:50015 50055 50057 ...
    50150:50154 50187 50188];
seriesE = [50005 50068 50149];

caldate_provenance = ['date in filename comes from latest ' ...
       'sensor caldate within QCT cap file'];

months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

con = rad_read_ctdbp_cap(capfilename);

%.. find latest sensor caldate to use in outputfilename
%.. format as read from xmlcon file is dd-mmm-yy
cdate = {con.caldate_temperature, con.caldate_conductivity, ...
    con.caldate_pressure};
for ii=1:length(cdate)
    mm = find(strcmpi(months, cdate{ii}(4:6)));  % get month number
    cdate{ii} = strcat('20', cdate{ii}(8:9), num2str(mm, '%2.2u'), ...
            cdate{ii}(1:2)); % yyyymmdd
end
cdate = sort(cdate);
cdate = cdate{end};

%.. also turn serial number (without model number) 
%.. into a 5 character string
sernum_5char = num2str(con.sernum, '%5.5u');

%.. find series based on serial number
if ismember(con.sernum, seriesC)
    series = 'C';
elseif ismember(con.sernum, seriesE)
    series = 'E';
else
    error('CTDBP Series cannot be determined from serial number.');
end

%.. construct output filename
csvfilename = ['CGINS-CTDBP' series '-' sernum_5char '__' cdate '.csv'];

%.. serial number to be written out inside of cal file;
%.. format is 16-XXXX for 4-digit serialnumbers, 16-XXXXX for 5.
template(1:22, 1) = {['16-' num2str(con.sernum)]};
%.. omaha coeff names
fnames = lower(fieldnames(con));  % lower case
fnames(1:4) = [];  % delete serial number and caldate fieldnames
template(1:22, 2) = cellfun(@(x) ['CC_' x], fnames, 'UniformOutput', 0);
%.. coeff values to be written out
C = struct2cell(con);
C(1:4) = [];  % also delete the first 4 elements of C 
template(1:22, 3) = C;

%.. alphabetically reorder coeffs to match what is already on github
template = template([1:4 21:22 17:20 14:16 8:13 5:7], :);

%.. add caldate provenance
template(1,4) = {caldate_provenance};

%.. write directly out to a text file, no xlsx in-between.
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';  %  'notes' is the 4th column
fprintf(fid, '%s\r\n', header);
fprintf(fid, '%s,%s,%s,%s\r\n', template{1, 1:4});
%.. append a comma to each line to denote an empty 4th column.
for ii = 2:length(template)
    fprintf(fid, '%s,%s,%s,\r\n', template{ii, 1:3});
end
fclose(fid);

%.. for on-screen checking of calcoeffs, especially if this routine
%.. has been called by the version of the 'export' code which has 
%.. been modified to open up the OOI csv file just written out in 
%.. notepad.
P = [1:8 25 26 21:24 18:20 12:17 9:11];
disp(orderfields(con, P));  % to match order in OOI csv calfile

end
