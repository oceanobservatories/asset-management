I have split the original bulk_load-AssetRecord.csv file into five separate pieces.

* array
* platform
* node
* sensor
* unclassified

Each of these files contains only the records whose TYPE column matches the file name, with unclassified containing all assets which do not specify a TYPE.

The vocab.csvs are look-up tables to use when adding entries to the corresponding bulk_load sheets. These tables contain consistent vocabulary for completing the 'DESCRIPTION OF EQUIPMENT', 'Manufacturer', and 'Model' fields.
