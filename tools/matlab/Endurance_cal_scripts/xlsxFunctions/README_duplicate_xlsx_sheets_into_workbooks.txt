To duplicate repeatedly a template sheet to a new workbook:

Excel=actxserver('Excel.Application');
Excel.Visible = -1;

WB=invoke(Excel.Workbooks,'open','d:\template.xlsx');
SHS=WB.Sheets; %sheets of template Workbook
SH=Excel.ActiveSheet; %active sheet of template Workbook

% The following makes a copy of the sheet, but to a new Workbook.
invoke(SH,'Copy')

nWB=Excel.ActiveWorkbook; %new Workbook
SH=Excel.ActiveSheet; %active sheet of new Workbook

nDup=10; %assuming I need to make 10 duplications of the same template sheet to the new workbook

for n=1:nDup-1 %the first sheet was already duplicated with the creation of the new Workbook

% The following makes a copy of all sheets (in this case only one sheet of the template) to the current Workbook (new Workbook)
invoke(SHS,'Copy',SH);

end
%.. maybe use this to get arrays in
[~,~,raw] = xlsread(outname,RAWsheetname);
xlswrite(filenameEnvelope, raw, envelopeSheetname)