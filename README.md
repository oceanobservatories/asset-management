# Asset Management
[![Build Status](https://travis-ci.org/ooi-integration/asset-management.svg?branch=master)](https://travis-ci.org/ooi-integration/asset-management)
A repository for Asset Management for OOI data.

## Folders
### ARCHIVE
Contains the legacy asset management spreadsheets.
These are not to be updated and exist only as a reference.
Once migration to the new asset management is complete, this ARCHIVE should be removed.

### IN_WORK
This folder is for any incomplete files which are not ready for ingestion. Once the file is complete it should be
moved to the appropriate folder based on file type.

### bulk
This folder contains the bulk CSV file(s).
The bulk file defines each asset in the system.

### calibration
This folder contains calibration CSV files. These files are organized by the five character instrument
class plus the one character series. Each file shall contain a complete set of calibration values for a
single calibration of a single instrument. The filename must comply with the following convention:

```
ASSET_UID__CALIBRATIONDATE.csv
```

Where the ASSET_UID is the unique identifier for the specific asset as defined in the bulk CSV file
and the CALIBRATIONDATE is the date of calibration in the format YYYYMMDD.

Internally, the calibration sheet contains the following columns:

* serial
* name
* value
* notes

The serial number MUST match the serial number as defined the in the bulk CSV.

All calibration values are expected to be valid JSON. For example:

* 1.23
* [2, 3, 4]
* [[1, 2], [3, 4]]

Any calibration values longer than the Excel single cell size limit of 32,767 characters shall
be represented in a separate CSV file. Currently this is utilized for the OPTAA taarray and tcarray
values. In this case, the value entry in the calibration CSV should take the form:

```
SheetRef:<CALIBRATION_NAME>
```

For example:

```
ACS-142,CC_tcarray,SheetRef:CC_tcarray,
```

The corresponding calibration values shall be placed in a separate CSV file using the following
naming convention:

```
ASSET_UID__CALIBRATIONDATE__CALIBRATIONNAME.ext
```

For example, for the Apr 9, 2015 calibration of A00595 (OPTAAC), the base file name is:

```
A00595__20150409.csv
```

And the files containing CC_taarray and CC_tcarray are:

```
A00595__20150409__CC_taarray.ext
A00595__20150409__CC_tcarray.ext
```

Notes are free form, limited to 256 characters.


### cruise

The cruise CSV file contains data specific to OOI cruises. The columns in the cruise CSV file are:

* CUID (cruise number)
* ShipName
* cruiseStartDateTime
* cruiseStopDateTime
* notes

The notes are free-form.

### deployment

Each deployment CSV contains one or more rows, each representing the deployment of a single asset.
The columns in the deployment CSV are as follows:

* CUID_Deploy
* deployedBy
* CUID_Recover
* recoveredBy
* Reference Designator
* deploymentNumber
* versionNumber
* startDateTime
* stopDateTime
* mooring.uid
* node.uid
* sensor.uid
* lat
* lon
* orbit
* deployment_depth
* water_depth
* notes

The CUID_Deploy and CUID Recover fields shall contain a cruise identifier defined in the cruises CSV file.
Deployment start and stop timestamps shall be in RFC 3339 format:

```
YYYY-MM-DDTHH:MM:SS
```

At a minimum, the reference designator, deployment number, version number, deployment start, mooring uid and sensor uid must be provided.

All files MUST end in _Deploy.csv. Beyond that, file naming is not restricted, but should follow a convention.
The existing files all use the following scheme:

```
PLATFORM_DEPLOYMENT_Deploy.csv
```

### test

This folder contains unit and integration tests associated with asset management data. All unit tests will
be executed automatically upon receipt of a pull request with the results viewable through the github pull
request interface.

### tools
#### convert

This folder is a temporary home to the scripts used to convert the existing data to the new format. This folder
will be removed when the ARCHIVE data is removed.

#### load

This folder contains scripts used to transform this CSV data into XLSX files as expected by edex.

#### cal_scripts

This folder contains scripts used to transform calibration data sheets from instrument manufacturers into calibration CSV files. These
are organized by instrument type.

### vessel

This folder contains the shiplist.csv file. The shiplist.csv file is a direct copy of the ship data provided by the 
Rolling Deck to Repository (R2R) program at http://www.rvdata.us/voc/vessel. The entries therein identify the ships 
for which R2R takes cruise Digital Object Identifier (DOI) minting responsibility. Ships that are not tracked by R2R 
should be omitted from the shiplist.csv file - the OOI CI may still record their cruise data and will take 
responsibility for minting their cruise DOIs.

### vocab

This folder contains the vocab.csv file and a script for ingesting vocab records, vocab_csv_ingest.py. The vocab 
entries in the vocab.csv file associate reference designators with other metadata, particularly TOC identifiers.
