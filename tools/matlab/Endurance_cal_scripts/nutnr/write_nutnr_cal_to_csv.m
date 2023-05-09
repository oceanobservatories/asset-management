function csvfilename = write_nutnr_cal_to_csv(calfilename)
%.. desiderio 29-sep-2017 update:
%.. ..
%.. .. isus to be deprecated;
%.. .. SUNAs to be used on surface moorings will be NUTNR_B
%
%.. desiderio 01-apr-2017
%       isus and suna instruments have exactly the same cal file format.
%         isus calfile names:  ISUS234A.CAL
%         suna calfile names:  SNA0234A.CAL
%
%.. reads in the Satlantic cal file calfilename and writes out the
%.. calcoeffs needed to write out a file to upload to the calibrations
%.. folder in the GitHub repository.
%
%.. NOW:
%..          ISUS: ALL ARE NUTNR-B
%..          SUNA: on cspp, NUTNR-J
%..          SUNA: on surface mooring, NUTNR-B
%..
%.. FUNCTION CALLS:
%.. cal = rad_read_nutnr_calfile(calfilename)

clear template

%.. SUNA serial numbers, for determining series
seriesB = [1056:1061 1115 1127:1129 1164 1167 1183];
seriesJ = [ 337  400  425  426   870   871]; 

[~, name, ext] = fileparts(calfilename);
caldate_provenance = ['date in filename comes from latest caldate ' ...
    'within calfile ' name ext];

months = {'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', ...
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'};

cal = rad_read_nutnr_calfile(calfilename);
%.. get caldate for filename; 
%.. format as read from Satlantic cal file is dd-mmm-yyyy
mm = find(strcmpi(months, cal.date(4:6)));  % get month number
cdate = [cal.date(8:11) num2str(mm, '%2.2u') cal.date(1:2)];  % yyyymmdd

%.. serial number 
template(1:7, 1) = {cal.sernum}; 
template(1:7, 2) = {'CC_lower_wavelength_limit_for_spectra_fit', ...
                    'CC_upper_wavelength_limit_for_spectra_fit', ...
                    'CC_cal_temp',                               ...
                    'CC_wl',                                     ...
                    'CC_eno3',                                   ...
                    'CC_eswa',                                   ...
                    'CC_di'                                          };

%.. coeff values to be written out
template{1, 3} = 217;
template{2, 3} = 240; 

%
%template{3, 3} = cal.tcal; 
%
%.. Sep 2017: some new calfiles also have a T_CAL_SWA line in their
%..           headers. According to Darrell Adams at Satlantic, the
%..           two entries are there for compatability with older and
%..           current software programs; the values will always be
%..           the same.
disp(['T_CAL     = ' num2str(cal.tcal)]);
disp(['T_CAL_SWA = ' num2str(cal.tcal_swa)]);
if ~isempty(cal.tcal_swa)
    template{3, 3} = cal.tcal_swa;
elseif isempty(cal.tcal)
    error('No tcal nor tcal_swa value found.');
else
    template{3, 3} = cal.tcal;
end

%.. for vectors written in JSON format, the sprintf statements terminate
%.. in ' ..., numx, numy, numz, ]' so that the penultimate 2 characters
%.. need to be deleted.
%
% wavelengths
template{4, 3} = ['[' sprintf('%.2f, ', cal.wvl) ']'];
template{4, 3}(end-2:end-1) = []; 
% nitrate extinction coefficients
template{5, 3} = ['[' sprintf('%.8f, ', cal.eno3) ']'];
template{5, 3}(end-2:end-1) = []; 
% temperature independent seawater extinction coefficients
template{6, 3} = ['[' sprintf('%.8f, ', cal.eswa) ']'];
template{6, 3}(end-2:end-1) = []; 
% reference distilled water spectrum
template{7, 3} = ['[' sprintf('%.8f, ', cal.ref) ']'];
template{7, 3}(end-2:end-1) = []; 

%.. construct output filename
%
%.. parse for series
if strcmpi(cal.instrument, 'ISUS')  % all ISUS's are 'B'
    series = 'B';
elseif strcmpi(cal.instrument, 'SUNA')
    %.. find series based on serial number
    if ismember(cal.sernum, seriesB)
        series = 'B';
    elseif ismember(cal.sernum, seriesJ)
        series = 'J';
    else
        disp(cal.sernum);
        errmsg = ['NUTNR(SUNA) series cannot be determined ' ...
                  'from serial number.'];
        error(errmsg);
    end
else
    error('Unknown NUTNR series.');
end
%.. the serial number was parsed from a 4 character field from both
%.. ISUS and SUNA calfiles; new 'SBE' SUNA SNs are 4 digits.
%.. (ISUS is no longer in production):
sernum = num2str(cal.sernum, '%4.4u');

csvfilename = ['CGINS-NUTNR' series '-0' sernum '__' cdate '.csv'];

%.. REORDER rows to match current entries in GitHub repository
template = template([3 7 5 6 1 2 4], :);

%.. add caldate provenance
template(1,4) = {caldate_provenance};

%.. write directly out to a text file, no xlsx in-between.
header = 'serial,name,value,notes';  %  'notes' is the 4th column
fid = fopen(csvfilename, 'w');
fprintf(fid, '%s\n', header);
%.. append a comma to each line to denote an empty 4th column.
%.. on github, an entry of an array is enclosed in double quotes.
fprintf(fid, '%i,%s,%.2f,%s\n', template{1, 1:4});
for ii = 2:4
    fprintf(fid, '%i,%s,"%s",\n', template{ii, 1:3});
end
fprintf(fid, '%i,%s,%i,\n', template{5, 1:3});
fprintf(fid, '%i,%s,%i,\n', template{6, 1:3});
fprintf(fid, '%i,%s,"%s",\n', template{7, 1:3});
fclose(fid);

end
