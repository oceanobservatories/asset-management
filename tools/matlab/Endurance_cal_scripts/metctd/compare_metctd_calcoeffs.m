function compare_metctd_calcoeffs
%.. desiderio 02-feb-2023 
%
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
%.. cap file coeffs sometimes show anomalies due to round off error,
%.. and sometimes (sbe16) cal file values of 0 appear as 0.000000e-41

%.. the outputs from the 'read' functions are isomorphic scalar structures
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

listing = cellstr(ls('*.*'));

% disp(' ');
% disp('The qct captured data files will all have an 'log' extension);
% disp(' ');

qctFile = listing(contains(listing, '.log'));
qctFile(contains(qctFile, {'doc' 'xls'})) = [];
if isempty(qctFile)
    error('Could not find qct file; it must contain ''*.log''.')
else
    qct = rad_read_metctd_cap(qctFile{1});
end
%
pdfFile = listing(contains(listing, '.pdf'));
if isempty(pdfFile)
    %disp('Could not find any *.pdf files.')
    PDF = struct2cell(qct);
    PDF(1:length(PDF)) = {'not found'};
    pdf = cell2struct(PDF, fieldnames(qct), 1);
else
    pdfC = pdfFile(contains(pdfFile, 'V2 C'));
    conC = rad_read_metctd_Cpdf(pdfC{1});
    pdfT = pdfFile(contains(pdfFile, 'V2 T'));
    conT = rad_read_metctd_Tpdf(pdfT{1});
    pdf = merge_metctd_TandC_calStructs(conT, conC);
end
%
calFile = listing(contains(listing, '.cal'));
if isempty(calFile)
    %disp('Could not find *.cal file.');
    CAL = struct2cell(qct);
    CAL(1:length(CAL)) = {'not found'};
    cal = cell2struct(CAL, fieldnames(qct), 1);
else
    cal = rad_read_metctd_cal(calFile{1});
end

field = fieldnames(qct);
%.. fields are character vectors (caldates and calcoeffs)
% 
%.. put the stat on the 1st line to condense screen height needed so
%.. that scrolling isn't needed to see all coeffs at once.
for ii = 1:length(field)
    if ii < 4   % serial number and caldates don't need stats
        disp([strtrim(field{ii}) ' pdf; qct; cal:' ])
        disp(pdf.(field{ii}))
        disp(qct.(field{ii}))
        disp(cal.(field{ii}))
    else
        % as long as i'm at it,
        % calculate the max deviation from the mean and divide it by the mean,
        % once the calcoeff section is reached
        arr = [str2double(pdf.(field{ii}))
            str2double(qct.(field{ii}))
            str2double(cal.(field{ii}))];
        arr(isnan(arr)) = [];  % if one is missing, still can get stat
        if prod(arr)==0
            noi = 0.0;
        else
            mmm = mean(arr);
            ddd = arr - mmm;
            noi = max(abs(ddd / mmm));
        end
        disp([field{ii} ':  |maxdev|/mean = ' num2str(noi)]);
        disp(pdf.(field{ii}))
        disp(qct.(field{ii}))
        disp(cal.(field{ii}))
    end
    if ii~=length(field), disp(' '); end
end
