#!/usr/bin/env python

"""
FLNTUA Calibration Parser
Create the necessary CI calibration ingest information from a FLNTUA
calibration file.
"""

__author__ = "Daniel Tran"
__version__ = "0.1.0"
__license__ = "MIT"

import datetime
import os
import time
from common_code.cal_parser_template import Calibration


class FLNTUACalibration(Calibration):
    """Calibration class for FLNTUA instruments.

    Attributes:
        chl (tuple): Dark count and scale factor values using chlorophyll 
                     concentrations.
        vol (tuple): Dark count and scale factor values using volume scatter.
        coefficients (dict): Dictionary containing all the relevant coefficients
                             associated with the instrument. These values will
                             be written to the appropriate CSV file.

    """

    def __init__(self):
        """Initializes the NUTNRACalibration Class."""

        super(FLNTUACalibration, self).__init__('FLNTUA')
        self.coefficients = {
            'CC_angular_resolution': 1.096,
            'CC_depolarization_ratio': 0.039,
            'CC_measurement_wavelength': 700,
            'CC_scattering_angle': 140
        }
        self.chl = None
        self.vol = None

    def read_cal(self, filename):
        """Reads cal file and scrapes it for calibration values. Rejects
           file if NTU file given and not volume scatter.
        
            Arguments:
                filename (str) -- path to the calibration file.
        
            Returns:
                True if file parsed successfully with volume scatter values.
                False if NTU file given. 
        
        """

        with open(filename, 'r') as fh:
            for line in fh:
                parts = line.split()
                if not len(parts):  # skip blank lines
                    continue
                if 'ECO' == parts[0]:
                    self.serial = parts[1]
                elif 'Created' == parts[0]:
                    self.date = datetime.datetime.strptime(
                        parts[-1], '%m/%d/%y')
                deconstruct = parts[0].split('=')
                if deconstruct[0].lower() == 'lambda':
                    self.vol = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_volume_scatter'] = parts[1]
                    self.coefficients['CC_dark_counts_volume_scatter'] = parts[2]
                elif deconstruct[0].upper() == 'NTU':
                    return False
                elif deconstruct[0] == 'Chl':
                    self.chl = (parts[1], parts[2])
                    self.coefficients['CC_scale_factor_chlorophyll_a'] = parts[1]
                    self.coefficients['CC_dark_counts_chlorophyll_a'] = parts[2]
            fh.close()
        return True


def main():
    """ Main entry point of the app """

    for path, _, files in os.walk('FLNTUA/manufacturer'):
        for file in files:
            # Skip hidden files
            if file[0] == '.':
                continue
            cal = FLNTUACalibration()
            if not cal.read_cal(os.path.join(path, file)):
                print("File does not have volume scatter: %s", file)
                continue
            cal.write_cal_info(os.path.join(path, file))


if __name__ == '__main__':
    start_time = time.time()
    main()
    print('FLNTUA: %s seconds' % (time.time() - start_time))
