function csvfilename = write_metctd_calcoeffs_to_csv(infilename)
%.. desiderio 30-jan-2023: creates an OOI csv calfile for METCTD sensors
%..                        which are SBE 37 CT (no 'D'epth) instruments 
%
%.. reads in calcoeffs from a sbe37 *.cal file (if infilename has a 'cal' 
%.. extension) or OOI qct of such (if infilename has any other extension,
%.. typically .cap, .log, or .txt). Has two function dependencies as 
%.. listed below.
%
%.. FUNCTION CALLS:
%.. [con] = rad_read_metctd_cal(sbe37calfilename)
%.. [con] = rad_read_metctd_cap(qctcapfilename)
%
%.. after csv file creation the pdf files are opened and
%.. the csv file is opened in Notepad for consistency check.
%


months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

[~, fnam, ext] = fileparts(infilename);
if strcmpi(ext, '.cal')
    con = rad_read_metctd_cal(infilename);
    source_provenance = ['source: ' fnam ext];
else
    con = rad_read_metctd_cap(infilename);
    %.. get qct sequence number for provenance
    idx = strfind(fnam, 'qct');
    qctseqnum = fnam(idx+3:idx+7);
    source_provenance = ['source: QCT 3305-00116-' qctseqnum];
end

%.. find latest sensor caldate to use in outputfilename
%.. format as read from infile is dd-mmm-yy
cdate = {con.caldate_temperature, con.caldate_conductivity};
for ii=1:length(cdate)
    mm = find(strcmpi(months, cdate{ii}(4:6)));  % get month number
    cdate{ii} = strcat('20', cdate{ii}(8:9), num2str(mm, '%2.2u'), ...
            cdate{ii}(1:2)); % yyyymmdd
end
cdate = sort(cdate);
cdate = cdate{end};

%.. also turn serial number (without model number) into 5 characters of text
%.. argument can either by real or char vector.
sernum_5char = num2str(con.sernum, '%5.5u');

%.. construct output filename
csvfilename = ['CGINS-METCTD-' sernum_5char '__' cdate '.csv'];

nrows = 11;  % of csv output file
%.. serial number to be written out inside of cal file;
%.. format is 37-XXXXX for 5.
template(1:nrows, 1) = {['37-' num2str(con.sernum)]};
%..  coeff names from the con file mimic those in the OOI csv calfile
fnames = lower(fieldnames(con));  % lower case
fnames(1:3) = [];  % delete serial number and caldate fieldnames
template(1:nrows, 2) = cellfun(@(x) ['CC_' x], fnames, 'UniformOutput', 0);
%.. coeff values to be written out
C = struct2cell(con);
C(1:3) = [];  % also delete the first 3 elements of C 
template(1:nrows, 3) = C;

% % %.. alphabetically reorder coeffs to match what is already on github
% % template = template([1:4 21:22 17:20 14:16 8:13 5:7], :);

%.. add caldate provenance
template(1,4) = {source_provenance};

fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';  %  'notes' is the 4th column
fprintf(fid, '%s\n', header);
fprintf(fid, '%s,%s,%s,%s\n', template{1, 1:4});
%.. append a comma to each line to denote an empty 4th column.
for ii = 2:nrows
    fprintf(fid, '%s,%s,%s,\n', template{ii, 1:3});
end
fclose(fid);

disp(con); 

%.. now check the OOI csv calfile coeffs.
%.. .. open the pdf file first, because using notepad introduces
%.. .. an automatic pause in code execution which can be used
%.. .. to compare the coeffs. when notepad is closed, execution
%.. .. will continue.
pdfFilename = ls('*.pdf');
if isempty(pdfFilename)
    disp('No pdf file found in instrument folder. Continue.');
else
    pdfFilename = strtrim(cellstr(ls('*.pdf')));
    %.. there could be 2 pdfs, one for T, one for C.
    for jj = 1:numel(pdfFilename)
        open(pdfFilename{jj});
    end
end
system(['notepad ' csvfilename]);
end
