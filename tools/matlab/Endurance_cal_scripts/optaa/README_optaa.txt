readme: optaa

write_optaa_dev_to_csv('acs127.dev');

I have also written 'CheckFunction' code which generates an excel file where the source ac-s devfile has been imported into the first sheet, the 3 OOI csv calfiles generated from it into the 3rd sheet, and the differences between their calibration coefficients are presented as formulas in the 2nd sheet (over a background of the ac-s devfile). Autofilling the formula cells should result in all differences calculating to 0 if the two files have the same calibration coefficient values. (A digital "watermark" of alternating differences of +\- 1.e-7 will also be observed.) Running the 'CheckFunction' code will require the Matlab path to include several matlab functions which call actxserver functions (located in the xlsxFunctions folder).