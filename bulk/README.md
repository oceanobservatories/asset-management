The original bulk_load-AssetRecord.csv file is split into separate pieces.

* array
* platform
* node
* sensor
* eng
* unclassified

Each of these files contains only the records whose TYPE column matches the file name, with unclassified containing all assets which do not specify a TYPE.

The components in the eng file are pulled from the sensor file.  They are engineering components (e.g., CPMs, DCLs, controllers), but their TYPE is still listed as sensor.

The vocab.csvs are look-up tables to use when adding entries to the corresponding bulk_load sheets. These tables contain consistent vocabulary for completing the 'DESCRIPTION OF EQUIPMENT', 'Manufacturer', and 'Model' fields.

Updated 2019-02-05 by S. N. White
