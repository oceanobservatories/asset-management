readme: nutnr

write_nutnr_cal_to_csv('SNA1128K.cal');
caldate is on the 4th line of the calfile, regardless of the cal type.

I have also written 'CheckFunction' code which generates an excel file where the source SUNA calfile has been imported into the first sheet, the OOI csv calfile generated from it into the 3rd sheet, and the differences between their calibration coefficients are presented as formulas in the 2nd sheet (over a background of the SUNA calfile). Autofilling the formula cells should result in all differences calculating to 0 if the two files have the same calibration coefficient values. (A digital "watermark" of alternating differences of +\- 1.e-7 will also be observed.) Running the 'CheckFunction' code will require the Matlab path to include several matlab functions which call actxserver functions (located in the xlsxFunctions folder).
