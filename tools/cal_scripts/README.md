# OOI Instrument Parsers

 The following scripts extract calibration information from various manufacturer calibration sheets. These calibration sheets define the values that various instruments use to calibrate themselves for data acquisition.
 These scripts automatically creates of calibration files in the format requested by ooi-integration.
 Serial numbers and asset tracking numbers can be found in the [sensor bulk file](
https://github.com/funnyabc/asset-management/blob/master/bulk/sensor_bulk_load-AssetRecord.csv) in the root repository.

The scripts currently support the creation of the following instrument types:
* CTD
* DOFSTA
* FLNTUA
* FLOR
* NUTNR
* OPTAA
* SPKIR

There is potential to create more scripts for more instruments, so feel free to contribute to this page.

These scripts are based on those written by Dan Mergens, who developed the original scripts which can still be found in the [ooi-tools](https://github.com/oceanobservatories/ooi-tools/tree/master/instrument/calibration) repository.

## Getting Started

Clone the repository into your local machine. In the repository, there are a set of directories of each of the supported instrument types. Navigate to the repository and in whatever terminal you are using or a file explorer system. There are a series of folders which contain the parsers and subdirectories containing manufacturer calibration files and completed csv files. Put the manufacturer calibration files in the "manufacturer" directory. This is where the parsers will search for files to parse.

### Prerequisites

* Python 2.7
* Linux terminal emulator

If you do not already have Python installed on your computer, you will need to install it to make this program work.
On Linux, run the following command.
```
sudo apt-get install python2.7
```
On MacOS, if you have Homebrew, call this command
```
brew install python2.7
```
On Windows, install Cygwin or preferred terminal emulator. Make sure to select python as part of the installation process.
Another method is to use the Linux Subsystem available on Windows 10.

If you need any packages needed in these files, you can use pip to help you install them.

 Linux, run the following command.
```
sudo apt-get install python-pip
```
On MacOS, if you have Homebrew, call this command
```
brew install pip
```
otherwise, use this command in your terminal:
```
sudo easy_install pip
```

To install a package, simply call the command in this format:

```
pip install <package>
```
## Running the code

To run the script, call it in this format.
```
python script_name.py
```

If there are multiple versions of Python on your system, such as Python 3, you may have to invoke the name of that version when calling the script.
```
python2.7 script_name.py
```

You can run each of the scripts individually by calling the corresponding parser.
```
python ctd_cal_parser.py
python dofsta_cal_parser.py
python flntua_cal_parser.py
python flor_cal_parser.py
python nutnr_cal_parser.py
python optaa_cal_parser.py
python spkir_cal_parser.py
```

The parsers will go through each file and add the completed files into the "Cal Sheets" folder in the respective instruments. If the number of files is equal

To run all scripts, call the script run_all_parsers.py:
```
python run_all_parsers.py
```

## Authors

* **Dan Mergens** - *Initial work of writing the scripts* - [danmergens](https://github.com/danmergens)
* **Daniel Tran** - *Modifications of scripts and setup of the parser system* - [funnyabc](https://github.com/funnyabc)

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details

## Acknowledgments

* Dan Mergens for starting the calibration scripts
