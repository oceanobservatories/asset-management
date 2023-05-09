function csvfilename = write_dosta_qct_to_csv(qct)
%.. desiderio 06-apr-2017
%
% APPEND CAL DATE FROM PDF TO QCT FILENAME: YYYYMMDD or YYYY-MM-DD
%
%.. reads in a DOSTA QCT which has been renamed by appending the
%.. calibration certificate's caldate to the filename and outputs
%.. a csv file to be uploaded to a calibration folder on the
%.. ooi-integration GitHub repository.
%
%.. after csv file creation the pdf file is opened and
%.. the csv file is opened in Notepad for consistency check.

seriesD = [134:136 217:223 291 292 313:315 477:480 482:485]; 
seriesJ = [209 308 350:353 646 672];  % 350 and 351 are whoi's
seriesM = [30 100 178];  % glider dostas borrowed for surface moorings

%.. glider dostas used on surface moorings must be double entered in bulk
%.. asset management as dostaM AND dostaD.
seriesD = [seriesD seriesM];

caldate_provenance = ['date in filename comes from ' ...
                      'factory calibration certificate'];
clear C D

fid = fopen(qct);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};

%.. parse serial number
idx = find(contains(C,'Serial Number'), 1);
D = textscan(C{idx}, '%s', 'whitespace', ' ', 'delimiter', '\t');
D=D{1};    % undo wrapping
sernum = D{4};
sernum_check = D{3};
if ~strcmp(sernum, sernum_check)
    error('Serial number values within QCT do not agree.');
end

%.. find series based on serial number
sernum = str2double(sernum);
if ismember(sernum, seriesD)
    series = 'D';
elseif ismember(sernum, seriesJ)
    series = 'J';
else
    error('DOSTA Series cannot be determined from serial number.');
end

%.. now convert serial number to 5 characters;
%.. this will work if serialnumbers > 999
sn_str = num2str(sernum, '%5.5u');

%.. find date of cal; this should have been appended 
%.. to the QCT infilename
[~, name, ~] = fileparts(qct);
%.. will accept either yyyy%mm%dd or yyyymmdd where % is usually a delimiter
caldate = name(end-9:end);
if strcmp(caldate(1:2), '20')
    caldate([5 8]) = [];
elseif strcmp(caldate(3:4), '20')
    caldate([1 2]) = [];
else
    error('Was caldate appended to QCT filename?');
end

%.. parse for so-called concentration coefficients
idx = find(contains(C,'ConcCoef'), 1);
D = textscan(C{idx}, '%s', 'whitespace', ' ', 'delimiter', '\t');
D=D{1};    % undo wrapping
offset = D{4};
slope  = D{5};

%.. parse for SVU (multipoint calibration) coefficients
idx = find(contains(C,'SVUFoilCoef'), 1);
D = textscan(C{idx}, '%s', 'whitespace', ' ', 'delimiter', '\t');
D = D{1};     % undo wrapping
D(1:3) = [];  % delete non-SVU elements

%.. construct output filename
csvfilename = ['CGINS-DOSTA' series '-' sn_str '__' caldate '.csv'];

%.. write directly out to a text file, no xlsx in-between.
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\n', header);
cc_array = ['[' offset ', ' slope ']'];
fprintf(fid, '%i,%s,"%s",%s\n', ...
    sernum, 'CC_conc_coef',cc_array,caldate_provenance);
%.. construct character array containing svu coeffs
svu_array = '[';
for ii = 1:length(D)
    svu_array = [svu_array D{ii} ', '];
end
svu_array(end-1:end) = [];
svu_array(end+1) = ']';
%.. and export
fprintf(fid, '%i,%s,"%s",\n', ...
    sernum, 'CC_csv',svu_array);
fclose(fid);

%.. now check the OOI csv calfile coeffs.
%.. .. open the pdf file first, because using notepad introduces
%.. .. an automatic pause in code execution which can be used
%.. .. to compare the coeffs. when notepad is closed, execution
%.. .. will continue.
pdfFilename = ls('*.pdf');
if isempty(pdfFilename)
    disp('No pdf file found in instrument folder. Continue.');
else
    %.. there could be 2 pdfs, one from Aanderaa, one from YSI.
    pdfFilename = strtrim(cellstr(ls('*.pdf')));
    for jj = 1:length(pdfFilename)
        open(pdfFilename{jj});
    end
end
system(['notepad ' csvfilename]);

end
