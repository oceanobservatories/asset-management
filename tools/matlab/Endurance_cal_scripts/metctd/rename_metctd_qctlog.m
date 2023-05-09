function [newName] = rename_metctd_qctlog(QCTfilename)
%.. desiderio 27-jan-2023
%..                        
%
%.. read in a METCTD (SBE37-CT) QCT log file, parse its serial number 
%.. and caldate, and rename it. QCT (logged) filenames are formatted as:
%
%..          3305-00116-XXXXX-A.*
%
%.. where XXXXX is the "protocol count" and the extension is QCT-operator
%.. generated, usually 'cap' but sometimes 'txt' or possibly 'log'.
%
%.. The renamed files will be of the form:
%
%..          metctd_snxxxxx_qctXXXXX_yyyymmdd.log
%
%.. where xxxxx is the SBE37 serial number and yyyymmdd is the calibration
%.. date of the instrument, taken to be the later of the caldates of the
%.. two sensors (temperature and conductivity).

months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};
              
fid = fopen(QCTfilename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};

%.. parse serial number into con data structure
SN     = C(contains(C, 'SERIAL NO. '));
idx    = strfind(SN{1}, 'SERIAL NO. ');
sernum = SN{1}(idx+11:idx+15);
%.. all the serial numbers are 5 dgits, except for 8028,
%.. which comes out as '8028 '
if sernum(end)==' '
    sernum = ['0' sernum(1:4)];
end
serialNumber = sernum;

%.. shotgun all caldates in the file
CD  = C(contains(C, '<CalDate>'));
%.. Some QCT logs do NOT have the calcoeffs in them due to operator error.
%.. trap those out.
if isempty(CD)
    disp(['PROBLEM! QCT log file ' QCTfilename ' does not contain calDate.'])
    newName = ['metctd_sn' serialNumber '_qct' QCTfilename(12:16) '_YYYYMMDD.log'];
    return
end

idx = strfind(CD{1}, '<CalDate>');
cal_dates(1:numel(CD)) = {''};
for ii = 1:numel(CD)
    cal_dates{ii} = CD{ii}(idx+9:idx+17);
    yyyy = ['20' cal_dates{ii}(8:9)];
    mmm  = cal_dates{ii}(4:6);
    mm   = num2str(find(matches(months, mmm, 'IgnoreCase', true)), '%2.2u');    
    dd   = cal_dates{ii}(1:2);
    cal_dates{ii} = [yyyy mm dd];
end
cal_dates = sort(cal_dates);
calDate = cal_dates{end};

newName = ['metctd_sn' serialNumber '_qct' QCTfilename(12:16) '_' calDate '.log'];
status = movefile(QCTfilename, newName);
if ~status
    disp(['Warning: could not rename file ' QCTfilename]);
end

return
%%
%{
%cd K:\METCTD\QCT
listing = sort(cellstr(ls('3305-00116*')));
for ii=1:numel(listing)
    lll{ii}=rename_metctd_qctlog(listing{ii});
    disp(lll{ii});
end
%}
