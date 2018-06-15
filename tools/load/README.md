# Loading Asset Management

Instructions for performing a clean install of asset management data.

### Create python virtualenv with the necessary modules

with virtualenv / pip:

```
mkvirtualenv asset_load
pip install -U pip
pip install pandas xlsxwriter
```

with conda:

```
conda create -n asset_load pandas xlsxwriter
source activate asset_load
```

### Generate the XLSX files

These instructions assume you are using all the files located in this
repository, but these scripts can be pointed at any directory containing
files in the appropriate format.

```
mkdir cruise deploy cal
./load_cruises.py ../../cruise cruise
./load_deploy.py ../../deployment deploy
./load_cal.py ../../calibration cal
```

### Remove existing asset management data

Now that all the input files are prepared we can purge the existing
data from the system. Note that once we purge this data retrieval of
asset information and production derived products will be affected
until we have completed reloading this data.

#### Drop data

Open the asset management database using a SQL editor. For example:
```
$ source activate pgcli
$ pgcli metadata awips
```

Then execute the following commands to drop the asset management tables:
```
truncate table xacquisition cascade;
truncate table xarray cascade;
truncate table xasset cascade;
-- truncate table xasset_xevents cascade;  -- if exists
truncate table xasset_xremoteresource cascade;
truncate table xassetstatusevent cascade;
truncate table xatvendor cascade;
truncate table xcalibration cascade;
truncate table xcalibrationdata cascade;
truncate table xcruiseinfo cascade;
truncate table xdeployment cascade;
truncate table xevent cascade;
truncate table xinstrument cascade;
truncate table xintegrationevents cascade;
truncate table xlocationevent cascade;
truncate table xmooring cascade;
truncate table xnode cascade;
truncate table xremoteresource cascade;
truncate table xretirement cascade;
truncate table xstorage cascade;
```

#### Reset sequences

```
alter sequence xasset_m_seq restart;
alter sequence xevent_seq restart;
```

### Load the cruise data

```
export XAD=/path/to/uframes/ooi/uframe-1.0/edex/data/ooi/xasset_spreadsheet
mv cruise/* $XAD
```

Observe the edex log, completion is indicated as follows:

```
INFO  2017-02-10 16:23:59,756 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] CruiseInfoSheetParser: EDEX - Processing sheet [CruiseInformation]:complete
INFO  2017-02-10 16:23:59,761 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XIngestor: EDEX - Completed processing file [/edex/data/ooi/xasset_spreadsheet/CruiseInformation.xlsx]
```

### Load the bulk asset data

Note, these files are located in the base of this repository in the folder
labeled "bulk"

```
cp array_bulk_load-AssetRecord.csv $XAD
cp platform_bulk_load-AssetRecord.csv $XAD
cp node_bulk_load-AssetRecord.csv $XAD
cp sensor_bulk_load-AssetRecord.csv $XAD
```

Each record ingested from a bulk file will create a log message like this:

```
INFO  2017-02-10 16:27:33,233 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XAssetSheetParser: EDEX - Created asset record [XArray] for uid = N00296
```

And the complete ingestion of a file will result in this:

```
INFO  2017-02-10 16:27:33,446 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XIngestor: EDEX - Completed processing file [/edex/data/ooi/xasset_spreadsheet/array_bulk_load-AssetRecord.csv]
```

Ensure that ALL bulk entries have been processed prior to proceeding.
This should take approximately one minute.

### Load the deployment and calibration data

Once the cruise and bulk information has been loaded the deployment
and calibration data can be loaded in any order.

```
mv deploy/* $XAD
mv cal/* $XAD
```

Deployment records produce log entries as follows:

```
INFO  2017-02-10 16:32:48,191 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XDeploymentDao: EDEX - Saving Deployment [CE07SHSP-SP001-09-PARADJ000:2:1]
INFO  2017-02-10 16:32:48,217 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XDeploymentDao: EDEX - Created Deployment [CE07SHSP-SP001-09-PARADJ000:2:1]
INFO  2017-02-10 16:32:48,218 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XDeploymentSheetParser: EDEX - Processing sheet [CE07SHSP_Deploy]:complete
INFO  2017-02-10 16:32:48,218 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XIngestor: EDEX - Completed processing file [/edex/data/ooi/xasset_spreadsheet/CE07SHSP_Deploy.xlsx]
```

And calibration records:

```
INFO  2017-02-10 16:34:21,121 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XIngestor: EDEX - Starting to process file [/edex/data/ooi/xasset_spreadsheet/ATAPL-58337-00003__20140929_Cal_Info.xlsx]
INFO  2017-02-10 16:34:21,133 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XCalibrationSheetParser: EDEX - Processing sheet [Asset_Cal_Info]:starting
INFO  2017-02-10 16:34:21,153 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XCalibrationSheetParser: EDEX - Calibration data added for sensor uid=ATAPL-58337-00003
INFO  2017-02-10 16:34:21,153 [Camel (camel-1) thread #7 - file:///edex/data/ooi/xasset_spreadsheet] XCalibrationSheetParser: EDEX - Processing sheet [Asset_Cal_Info]:complete
```

As files are processed they are removed from the ingest folder ($XAD).
Once this folder is empty ingestion is complete. This should take
approximately five minutes.
