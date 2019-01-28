#!/usr/bin/env python3
"""
Common code shared between the different parsers in this file. Includes a
Calibration object that defines some default fields and functions.
Also includes a function to parse through a csv that shows the link
between serial numbers and UIDs.
"""

__author__ = "Daniel Tran"
__version__ = "0.1.0"
__license__ = "MIT"

import csv
import datetime
import os
import pandas as pd
import sqlite3
import time


class Calibration(object):
    """Template for a calibration object that can be used as a base for 
       various instrument parsers

    Attributes:
        asset_tracking_number (str): Asset UID
        serial (str): Serial number associated with the instrument.
        date (datetime): Date when the calibration was performed
        coefficients (dict): Dictionary containing all the relevant coefficients
                             associated with the instrument. These values will
                             be written to the appropriate CSV file.
        type (str): Type of instrument the calibration file is for.

    """

    def __init__(self, type, serial=None, coefficients={}, 
                 asset_tracking_number=None):
        """Initializes the Calibration Class.
        
        Args:
            type (str): Type of instrument the calibration file is for.
            serial (str): Serial number associated with the instrument.
            coefficients (dict): Dictionary of coefficient labels with their
                                 numerical values.

        """

        self.asset_tracking_number = asset_tracking_number
        self.coefficients = coefficients
        self.date = None
        self.serial = serial
        self.type = type


    def write_cal_info(self, file):
        """Writes data to a CSV file in the format defined by OOI integration.
           Also deletes the file used for creating the CSV file.

           Args:
               file (str): name of calibration file to delete.

        """

        if not self.get_uid():
            return
        complete_path = os.path.join(os.path.realpath('../..'), 'calibration',
                                     self.type)
        file_name = '{0}__{1}.csv'.format(self.asset_tracking_number, self.date.strftime('%Y%m%d'))
        with open(os.path.join(complete_path, file_name),
                  'w') as info:
            writer = csv.writer(info)
            writer.writerow(['serial','name', 'value', 'notes'])
            for each in sorted(self.coefficients.items()):
                row = [self.serial] + list(each)
                row.append('')
                writer.writerow(row)
            info.close()
        os.remove(file)


    def move_to_archive(self, inst_type, file):
        """Moves parsed calibration file to the manufacturer_ARCHIVE
           directory.
           DEPRECATED 2019-01-24 Protocol now is to delete file.
        Args:
            inst_type (str): type of instrument that indicates which folder to
                             move in the calibration directory.
            file (str): name of the file to move.

        """

        os.rename(os.path.join(os.getcwd(), inst_type, 'manufacturer', file), \
                    os.path.join(os.getcwd(), inst_type,
                                 'manufacturer_ARCHIVE', file))
        

    def get_uid(self):
        """Retrieves the ASSET UID of the instrument according to its serial number.

        Returns:
            True if a corresponding UID is found. False otherwise.

        """
        # TODO: Implementation involving sensor bulk load.
        # sensor_bulk_path = os.path.join(os.path.realpath('../..'), 'bulk', 'sensor_bulk_load-AssetRecord.csv')
        # sensor_bulk_load = pd.read_csv(sensor_bulk_path)
        # asset_serial_mapping = sensor_bulk_load[['ASSET_UID', 'Manufacturer\'s Serial No./Other Identifier']]
        # self.asset_tracking_number = asset_serial_mapping.loc[asset_serial_mapping['Manufacturer\'s Serial No./Other Identifier'] == self.serial]

        sql = sqlite3.connect('instrumentLookUp.db')
        uid_query_result = sql.execute('select uid from instrument_lookup where serial=:sn',\
                                       {'sn':self.serial}).fetchone()
        if len(uid_query_result) != 1:
            return False
        self.asset_tracking_number = uid_query_result[0]
        return True
