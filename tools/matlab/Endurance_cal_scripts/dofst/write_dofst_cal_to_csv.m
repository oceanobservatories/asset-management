function write_dofst_cal_to_csv(calfilename)
%.. desiderio 19-apr-2017
% (For McLane profilers, CE09OSPM).
%
%.. reads in the Seabird 43F O2 text calfile and writes out the
%.. calcoeffs to a csv file to upload to the calibrations folder 
%.. in the assetManagement GitHub repository.

%************ ALTERATION OF FACTORY CALFLE IS REQUIRED *****************
%***********************************************************************
%***********************************************************************
%***********************************************************************
%         USE SOC ***ADJUSTED***
%   which is only listed in a certain PDF file, not in the following
%   calfile. (9/27/2019: it *is* in this turn's calfile).
%***********************************************************************
%***********************************************************************
%***********************************************************************
%
%.. unaltered SAMPLE CALFILE direct from Seabird - 2496.cal:
%
% INSTRUMENT_TYPE=SBE43F
% SERIALNO=2496
% OCALDATE=11-Nov-16
% SOC= 2.710342e-004
% FOFFSET=-8.683700e+002
% A=-4.973297e-003
% B= 2.973403e-004
% C=-4.585230e-006
% E= 3.600000e-002
% Tau20= 1.250000e+000
%***********************************************************************
%***********************************************************************
%.. I will alter the original SBE .cal file by adding two lines
%.. taken from the pdf of the adjusted cal as follows. Note that the
%.. only calcoeff which is changed is Soc. And, because the calibration
%.. date within the pdf is the old cal date (in this case 11-Nov-16),
%.. insert the adjusted caldate (in this case taken from the pdf filename)
%.. into the cal file itself.
%
%.. the order of the rows is not signficant.
%
%.. SAMPLE desiderio-adjusted CALFILE - 2496adj.cal:
%
% INSTRUMENT_TYPE=SBE43F
% SERIALNO=2496
% OCALDATE=11-Nov-16
% SOC= 2.710342e-004
% FOFFSET=-8.683700e+002
% A=-4.973297e-003
% B= 2.973403e-004
% C=-4.585230e-006
% E= 3.600000e-002
% Tau20= 1.250000e+000
% ADJCALDATE=20161207
% ADJSOC=2.8589e-004
%***********************************************************************
%***********************************************************************

% cd R:
% cd ..

%.. read in calcoeff values as strings
value(1:6) ={''};
nvalues = length(value);

caldate_provenance = 'date in filename comes from Soc-adjusted caldate';
Soc_type = 'this is the adjusted Soc (O2 signal slope) value';

%.. set up character strings for write-out loop
notes = {caldate_provenance, ...
         Soc_type,            ...
         '',                  ...
         '',                  ...
         '',                  ...
         ''                   };

coeffname = {'CC_frequency_offset',                          ...
             'CC_oxygen_signal_slope',                       ...
             'CC_residual_temperature_correction_factor_a',  ...
             'CC_residual_temperature_correction_factor_b',  ...
             'CC_residual_temperature_correction_factor_c',  ...
             'CC_residual_temperature_correction_factor_e'   };

identifier = {'FOFFSET=', ...
              'ADJSOC=',  ...
              'A=',       ...
              'B=',       ...
              'C=',       ...
              'E='        };

clear C

fid = fopen(calfilename);
%.. read in all lines.
C = textscan(fid, '%s', 'whitespace', '', 'delimiter', '\n');
fclose(fid);
%.. get rid of wrapping cell array
C = C{1};
          
%.. read in serial number
sernumC = C(strncmpi('SERIALNO=', C, 9));
if isempty(sernumC), error('Could not find serial number.'); end
sernumFix = str2double(sernumC{1}(10:end));  % integer
%.. read in caldate
caldate = C(strncmpi('ADJCALDATE', C, 10));
if isempty(caldate), error('Could not find adjsuted caldate.'); end
caldate = caldate{1}(end-7:end);  % yyyymmdd
%.. read in calcoeff calues
for ii=1:nvalues
    clear D
    nlen = length(identifier{ii});
    D = C(strncmpi(identifier{ii}, C, nlen));
    if isempty(D)
        error(['Could not find ' '''' identifier{ii} '''']);
    end
    value{ii} = strtrim(D{1}(nlen+1:end));
end

%.. get a 5 character serialnumber string regardless of whether
%.. sernumFix is 4 or 5 digits
sernumstr = ['0' num2str(sernumFix)];
sernumstr = sernumstr(end-4:end);
%.. construct outfile name
csvfilename = ['CGINS-DOFSTK-' sernumstr '__' caldate '.csv'];

%.. serial number string for calfile entry
sernumstr = ['43-' num2str(sernumFix)];
fid = fopen(csvfilename, 'w');
header = 'serial,name,value,notes';
fprintf(fid, '%s\r\n', header);
for ii = 1:nvalues
    fprintf(fid, '%s,%s,%s,%s\r\n', ...
        sernumstr, coeffname{ii}, value{ii}, notes{ii});
end
fclose(fid);

end
