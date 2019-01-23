#!/usr/bin/env python

# OPTAA calibration parser
#
# Create the necessary CI calibration ingest information from an OPTAA calibration file

import csv
import datetime
import dateutil.parser
import os
import json
import string
import sys
import time
from common_code.cal_parser_template import Calibration


class OPTAACalibration(Calibration):
    def __init__(self, serial):
        """Initializes the OPTAACalibration Class.
        
        Args:
            serial (str): serial number for the OPTAA
        
        """
        
        self.asset_tracking_number = None
        self.cwlngth = []
        self.awlngth = []
        self.tcal = None
        self.tbins = None
        self.ccwo = []
        self.acwo = []
        self.tcarray = []
        self.taarray = []
        self.nbins = None  # number of temperature bins
        self.serial = serial
        self.date = None
        self.coefficients = {
            'CC_taarray': 'SheetRef:CC_taarray',
            'CC_tcarray': 'SheetRef:CC_tcarray'
        }
        self.type = 'OPTAA'

    def read_cal(self, filename):
        """Reads cal file and scrapes it for calibration values.
        
        Arguments:
            filename (str) -- path to the calibration file.
        """
        
        with open(filename) as fh:
            for line in fh:
                parts = line.split(';')
                if len(parts) != 2:
                    parts = line.split()
                    if parts[0].lower() == '"tcal:':
                        self.tcal = parts[1]
                        self.coefficients['CC_tcal'] = self.tcal
                        cal_date = parts[-1:][0].strip(string.punctuation)
                        cal_date = dateutil.parser.parse(cal_date, dayfirst=False, 
                                                         yearfirst=False)
                        self.date = cal_date.strftime('%Y%m%d')
                    continue
                data, comment = parts

                if comment.startswith(' temperature bins'):
                    self.tbins = data.split()
                    self.tbins = [float(x) for x in self.tbins]
                    self.coefficients['CC_tbins'] = json.dumps(self.tbins)

                elif comment.startswith(' number of temperature bins'):
                    self.nbins = int(data)

                elif comment.startswith(' C and A offset'):
                    if self.nbins is None:
                        print('Error - failed to read number of temperature bins')
                        sys.exit(1)
                    parts = data.split()
                    self.cwlngth.append(float(parts[0][1:]))
                    self.awlngth.append(float(parts[1][1:]))
                    self.ccwo.append(float(parts[3]))
                    self.acwo.append(float(parts[4]))
                    tcrow = [float(x) for x in parts[5:self.nbins+5]]
                    tarow = [float(x)
                             for x in parts[self.nbins+5:2*self.nbins+5]]
                    self.tcarray.append(tcrow)
                    self.taarray.append(tarow)
                    self.coefficients['CC_cwlngth'] = json.dumps(self.cwlngth)
                    self.coefficients['CC_awlngth'] = json.dumps(self.awlngth)
                    self.coefficients['CC_ccwo'] = json.dumps(self.ccwo)
                    self.coefficients['CC_acwo'] = json.dumps(self.acwo)
            fh.close()

    def write_cal_info(self):
        """Writes data to a CSV file in the format defined by OOI integration"""
        
        inst_type = None
        self.get_uid()
        if self.asset_tracking_number.find('58332') != -1:
            inst_type = 'OPTAAD'
        elif self.asset_tracking_number.find('69943') != -1:
            inst_type = 'OPTAAC'
        complete_path = os.path.join(
            os.path.realpath('../..'), 'calibration', inst_type)
        file_name = '{0}__{1}'.format(self.asset_tracking_number, self.date)
        with open(os.path.join(complete_path, '{0}.csv'.format(file_name)), 'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial', 'name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                writer.writerow([self.serial] + list(each))

        def write_array(filename, cal_array):
            with open(filename, 'w') as out:
                array_writer = csv.writer(out)
                array_writer.writerows(cal_array)
            out.close()

        write_array(os.path.join(complete_path, '{0}__CC_tcarray.ext'.format(
                                 file_name)), self.tcarray)
        write_array(os.path.join(complete_path, '{0}__CC_taarray.ext'.format(
                                 file_name)), self.taarray)
        info.close()


def main():
    for path, _, files in os.walk('OPTAA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            sheet_name = os.path.basename(file).partition('.')[0].upper()
            serial = sheet_name[:3] + '-' + sheet_name[3:6]
            cal = OPTAACalibration(serial)
            cal.read_cal(os.path.join(path, file))
            cal.write_cal_info()
            cal.move_to_archive(cal.type, file)


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('OPTAA: %s seconds' % (time.time() - start_time))
