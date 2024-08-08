# RCA calibration entry workflow

## Files to parse for each instrument:
CTD: .xmlcon (has higher resolution than .pdf or .cal)
FLCDRA: .dev
FLNTUA: .dev.lambda (dev file with volume scattering); both .dev files get posted to cal repo, but only lambda is parsed into asset management
FLORDD: .dev.lambda (dev file that includes lambda coefficients; named .dev on the google drive, and we add “.lambda” to the end during the rename process)
OPTAA: .dev (both cal and dev files get posted to cal repo, but only dev is parsed into asset management)
Cal script produces 3 files in asset management…
Cal file is the air cal, dev file is the pure water cal
SPKIRA: .cal
DOFSTA: .cal (has higher resolution than .xml or .pdf)
NUTNR: .cal
## Files to manually enter from pdf:
DOSTAD
PHSEN
PCO2W
PAR
## Files that are not vendor cals:
VEL3DA: comes from deep profiler team

## Calibration Workflow Notes 
1) Make sure all subfolders cal_scripts are empty on your working branch
2) Move manufacturer cal file into CTD/manufacturer
3) Example for CTD. Download all the ctd vendor cal files from the google drive where they have 
been renamed with standard name convention. Put them in the `cal_scripts/CTD/manufacturer` folder in asset management
4) Then run the tools/cal_scripts/CTD_cal_parser.py. 
5) Last move the vender cal files into the RCA cal file repo and delete the vendor cal files in 
the OOI asset_managment repo (on your working branch).

### NOTE
RCA_sensormap.csv maps asset id to serial number and sensor type, if there is a new sensor or sensor type, this 
file may need to be updated.

## Workflow for manual ingestion of calibration coefficients
1) Go into folder asset_manangemnt/calibration/<<INSTURMENT_TYPE>>
2) Take a look at one of the csv files from the past years
3) Copy csv to maintain consistent format, but be sure **rename to new calibration date**
4) Lastly, for RCA recordkeeping and quality assurance, go to the RCA assetManagment repo `2i_HITL/calibration_verification.csv`
and add the name of the files entered manually. 
5) All manual calibrations **MUST** be reviewed by at least one other person. After this review enter the initials 
of the reviewer and and date reviewed into `2i_HITL/calibration_verification.csv`. 