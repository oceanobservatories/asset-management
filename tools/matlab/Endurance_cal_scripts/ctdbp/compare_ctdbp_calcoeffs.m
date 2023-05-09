function compare_ctdbp_calcoeffs
%.. desiderio 26-feb-2020
%.. desiderio 15-mar-2021 converted to function, this function is called by
%..                       compare_ctdbp_calcoeffs_IN_FOLDERTREE.m
%.. desiderio 14-feb-2023 also opens T,P,C pdfs in acrobat so that those
%..                       coeffs can be compared to those in the matlab
%..                       command window.
%.. FUNCTION CALLS
%.. rad_read_ctdbp_cal.m
%.. rad_read_ctdbp_cap.m
%.. rad_read_ctdbp_xmlcon.m
%
%.. the working directory must contain the vendor documentation
%.. containing the calcoeffs to be compared:
%..     xmlcon, QCT cap, cal, and pdfs.
%
%.. OUTPUTS EACH CALCOEFF FROM THESE 3 SOURCES TO THE MATLAB COMMAND WINDOW
%.. FOR EASE OF COMPARISON. PDFs are also opened.
%
% xml; qct; cal:
%
% PTCA0
% 5.25037077e+005  (xmlcon)
% 5.250372e+05     (qct)
% 5.250371e+005    (cal)
%
%.. xmlcon coeffs usually have 2 more sigfigs than those in the other files.
%.. cap file coeffs sometimes show anomalies due to round off error, as in the
%.. above example, and sometimes cap file values of 0 appear as 0.000000e-41

%.. the outputs from the 'read' functions are isomorphic scalar structures

%.. reorder the ctd calcoeffs so that the pressure coeffs are in the
%.. same order as displayed on the pdf calsheet.
%.. .. before reordering (the last 4 pressure coeffs need to be the 1st 4):
%.. SN(1) caldates(3) T(4) P(12) C(6)
reorderCC = [1:8 18:20 9:17 21:26];

listing = cellstr(ls('*.*'));

% disp(' ');
% disp('The qct captured data file must start with ''3305-00102-''.');
% disp(' ');

qctFile = listing(contains(listing, '3305-00102-'));
qctFile(contains(qctFile, {'doc' 'xls'})) = [];
if isempty(qctFile)
    error('Could not find qct file; it must contain ''3305-00102-''.')
else
    qct = rad_read_ctdbp_cap(qctFile{1});
end
%
xmlconFile = listing(contains(listing, '.xmlcon'));
if isempty(xmlconFile)
    disp('Could not find *.xmlcon file.')
    XML = struct2cell(qct);
    XML(1:length(XML)) = {'not found'};
    xml = cell2struct(XML, fieldnames(qct), 1);
else
    xml = rad_read_ctdbp_xmlcon(xmlconFile{1});
end
%
calFile = listing(contains(listing, '.cal'));
if isempty(calFile)
    disp('Could not find *.cal file.');
    CAL = struct2cell(qct);
    CAL(1:length(CAL)) = {'not found'};
    cal = cell2struct(CAL, fieldnames(qct), 1);
else
    cal = rad_read_ctdbp_cal(calFile{1});
end

disp('xml; qct; cal:');
disp(' ');
field = fieldnames(qct);
field = field(reorderCC);
%.. first field is numeric (serial number)
for ii = 1:1
    disp(field{ii})
    disp(num2str(xml.(field{ii})))
    disp(num2str(qct.(field{ii})))
    disp(num2str(cal.(field{ii})))
    disp(' ');
end
%.. all other fields are character vectors (caldates and calcoeffs)
for ii = 2:length(field)
    disp(field{ii})
    disp(xml.(field{ii}))
    disp(qct.(field{ii}))
    disp(cal.(field{ii}))
    % as long as i'm at it, 
    % calculate the max deviation from the mean and divide it by the mean,
    % once the calcoeff section is reached
    if ii < 5, disp(' '), continue, end
    arr = [str2double(xml.(field{ii}))
           str2double(qct.(field{ii})) 
           str2double(cal.(field{ii}))];
    if prod(arr)==0
        noi = 0.0;
    else
        mmm = mean(arr);
        ddd = arr - mmm;
        noi = max(abs(ddd / mmm));
    end
    disp(['|maxdev|/mean = ' num2str(noi)]);
    disp(' ');
end
%.. now open T, P, and C pdfs on monitor:
pdfFile = sort(listing(contains(listing, '.pdf')));
if numel(pdfFile)~=3
    disp('Warning, 3 pdfFiles were not found');
    for ii=1:numel(pdfFile)
        open(pdfFile{ii});
    end
else
    %.. open the pdf files in the same order as coeffs are displayed
    %.. in the command window
    for ii=[3 2 1]
        open(pdfFile{ii});
        pause(1.0);  % needed so that pdfs open in desired order.
    end
    %.. opening order: T, P, C; order in matlab command window is T, P, C.
    %.. Scroll command window as needed to view corresponding cdoeffs.
end