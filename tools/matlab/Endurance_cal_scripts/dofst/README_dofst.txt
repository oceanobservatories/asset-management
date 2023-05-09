readme: dofst

write_dofst_cal_to_csv('3535adj.cal');

The documentation below is taken from the start 
of the source code "write_dofst_cal_to_csv.m"

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