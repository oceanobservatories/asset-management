function delete_default_worksheets(xls_filename)
%.. delete default worksheets 1,2,3.
%.. first make sure that these sheets exist - if they don't, then
%.. the excel file will be remain 'open', not editable, and not
%.. delete-able (must go into task manager and delete excel processes
%.. to fix this).
%
%.. get all the sheetnames
[~, all_sheets] = xlsfinfo(xls_filename);
%.. sheet_delete is 1 (true) if all 3 sheets are present
sheet_delete = all(ismember({'Sheet1','Sheet2','Sheet3'}, all_sheets));
if sheet_delete
    try
        objExcel = actxserver('Excel.Application');
        objExcel.Workbooks.Open(xls_filename);
        objExcel.ActiveWorkbook.Worksheets.Item('Sheet1').Delete;
        objExcel.ActiveWorkbook.Worksheets.Item('Sheet2').Delete;
        objExcel.ActiveWorkbook.Worksheets.Item('Sheet3').Delete;
        objExcel.ActiveWorkbook.Save;
        objExcel.ActiveWorkbook.Close;
        objExcel.Quit;
        objExcel.delete;
    catch
        disp('Note - deletion of default worksheets did not work.');
    end
end

end
