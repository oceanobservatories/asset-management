function comparePRESFcsvCalfiles(file1, file2)
%.. desiderio 24-feb-2023 accepts two calling arguments each naming an OOI
%..                       csv calfile from the same SBE26P (PRESF) sensor
%..                       and compares their cal coeffs; these are 
%..                       for pressure and usually (never?) change,
%..                       except for a particular OFFSET 
%

T1 = sortrows(readtable(file1));
T2 = sortrows(readtable(file2));
names = char(T2{:, 2});  % should be the same for both
S1 = table2struct(T1);
S2 = table2struct(T2);

for ii = 1:numel(S1)
    if ~strcmp(S1(ii).name, S2(ii).name)
        error('The two input files must have the same set and ordering of cal coeffs.')
    end
    vals = [S1(ii).value S2(ii).value];
    disp(['diff = ' num2str(diff(vals), '%9.4f') ': ' names(ii, :) ': ' num2str(vals)]);
    %disp(['diff = ' num2str(diff(vals), '%9.4f') ': ' num2str(vals) '; ' S1(ii).name ]);
    %disp([names(ii, :) ': diff = ' num2str(diff(vals), '%9.4f') ': '  num2str(vals)]);
end
        