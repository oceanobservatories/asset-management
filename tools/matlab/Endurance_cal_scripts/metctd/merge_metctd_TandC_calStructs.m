function [con] = merge_metctd_TandC_calStructs(conT, conC)
%.. desiderio 31-jan-2023: creates a metctd con structure 
%
%.. conT and conC are structures containing calcoeff info from the
%.. T and C sensors of a metctd (SBE37) instrument. One must contain 
%.. 'T' calcoeffs contained in a data structure most conveniently
%.. generated using rad_read_metctd_Tpdf; the other 'C' calcoeffs
%.. generated using rad_read_metctd_Cpdf.
%
%.. the output structure con is a melding of the two.

%.. both input and output structures have these fields in this order.
calFields = {
    'sernum'
    'caldate_temperature'
    'caldate_conductivity'
    'A0'
    'A1'
    'A2'
    'A3'
    'G'
    'H'
    'I'
    'J'
    'CPCOR'
    'CTCOR'
    'WBOTC'
    };

fieldsT = [1 2 4:7];
fieldsC = [3 8:14];

%.. initialize
for ii = 1:numel(calFields)
    con.(calFields{ii}) = '';
end

%.. checks
if ~strcmp(conT.sernum, conC.sernum)
    error('Constituent structures have different serial numbers.')
end
%.. require that each input is either 'C' or 'T', and, one of each
tf_conT_T = ~isempty(conT.caldate_temperature);
tf_conT_C = ~isempty(conT.caldate_conductivity);
tf_conC_T = ~isempty(conC.caldate_temperature);
tf_conC_C = ~isempty(conC.caldate_conductivity);

errFlag = false;
%
if (~tf_conT_T)
    disp('First calling structure must have ''T'' data.')
    errFlag = true;
end
if (tf_conT_C)
    disp('First calling structure must not have ''C'' data.')
    errFlag = true;
end
%
if (~tf_conC_C)
    disp('Second calling structure must have ''C'' data.')
    errFlag = true;
end
if (tf_conC_T)
    disp('Second calling structure not have ''T'' data.')
    errFlag = true;
end
if errFlag
    error('Execution terminated.')
end

%.. write in T coeffs
for ii = fieldsT
    con.(calFields{ii}) = conT.(calFields{ii});
end
%.. write in C coeffs
for ii = fieldsC
    con.(calFields{ii}) = conC.(calFields{ii});
end
    
    
    
    
