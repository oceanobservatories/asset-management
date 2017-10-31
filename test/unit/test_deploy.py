import fnmatch
import logging
import os
import pandas
from nose.plugins.attrib import attr

from test.test_base import AssetManagementUnitTest

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)


@attr('UNIT')
class DeploymentFilesUnitTest(AssetManagementUnitTest):
    asset_map = {
        'mooring.uid': 'Platform',
        'sensor.uid': 'Sensor',
        'node.uid': 'Node'
    }

    required_ids = {
        'CUID_Deploy',
        'Reference Designator',
        'deploymentNumber',
        'startDateTime',
        'mooring.uid',
        'sensor.uid',
        'lat',
        'lon',
    }

    optional_ids = {
        'deployedBy',
        'CUID_Recover',
        'recoveredBy',
        'versionNumber',
        'stopDateTime',
        'node.uid',  # only required for profilers
        'orbit',
        'depth'
    }

    def setUp(self):
        """
        Read bulk load asset management data and save UID and serial numbers
        """
        super(DeploymentFilesUnitTest, self).setUp()
        # dictionary of all the UIDs and corresponding serial numbers
        self.ids = {str(record.uid): str(record.asset_type) for _, record in self.bulk_data.iterrows()}
        self.cruise_ids = set(self.cruise_data.CUID.values)

    def check_type_match(self, record, asset_key):
        """
        verify UIDs exist and match type
        :param record:
        :param asset_key:  one of the three asset record headings (mooring.uid, sensor.uid, node.uid)
        :return:  list of errors (if any)
        """
        if asset_key not in self.asset_map.keys():
            return 'Unexpected asset type provided (%s not one of %r)' % (asset_key, self.asset_map.keys())

        # make sure the asset has a UID loaded from bulk load
        asset_type = self.asset_map[asset_key]
        asset = str(record[asset_key])

        # nodes are optional, skip check if not present
        if asset_key == 'node.uid' and not asset:
            return

        if asset not in self.ids:
            return 'Missing UID for %s %s' % (asset_type, asset)

        if self.ids[asset] != asset_type:
            return 'Type mismatch for %s - expected "%s", found "%s"' % (asset_key, asset_type, self.ids[asset])

    def check_deploy_file(self, fn):
        """
        Check a single deployment file for format and consistency
        :param fn:  deployment filename
        :return:  list of errors (if any)
        """
        errors = []
        deployment = pandas.read_csv(fn).fillna('')

        # TODO: remove this once uframe has been updated
        # Drop water_depth and rename deployment_depth to depth until
        # the parser in uframe is updated to reflect these changes
        deployment.rename(columns={'deployment_depth': 'depth'}, inplace=True)
        deployment.drop('water_depth', 1, inplace=True)

        # make sure all fields are present
        missing = self.required_ids.union(self.optional_ids) - set(deployment.columns)
        if missing:
            errors.append('Missing required column identifiers: %s' % missing)

        # check types for Platform and Sensor
        for index, record in deployment.iterrows():
            try:
                # rows which begin with # are considered comments
                if record.CUID_Deploy.startswith('#'):
                    continue

                # make sure all required fields are filled out
                set_fields = {name for name in record.index if getattr(record, name)}
                missing = self.required_ids - set_fields
                if missing:
                    errors.append('Missing value(s) for required fields: %s on row %d - %r' %
                                  (missing, index, record.values))
                    return errors

                # make sure the cruise ID exists
                deploy_cuid = record.CUID_Deploy
                if deploy_cuid and deploy_cuid not in self.cruise_ids:
                    errors.append('Invalid cruise ID - "%r" - row %d' % (deploy_cuid, index))

                recover_cuid = record.CUID_Recover
                if recover_cuid and recover_cuid not in self.cruise_ids:
                    errors.append('Invalid cruise ID - "%r" - row %d' % (recover_cuid, index))

                # check asset types for matching UID records
                for asset_type in self.asset_map.keys():
                    error = self.check_type_match(record, asset_type)
                    if error:
                        errors.append(error + ' - row %d' % index)

                # start and stop (if present) must have correct format
                start_time = record['startDateTime']
                if start_time and not self.valid_time_format(start_time):
                    errors.append('Invalid time format for startDateTime - "%r" - row %d' % (start_time, index))

                stop_time = record['stopDateTime']
                if stop_time and not self.valid_time_format(stop_time):
                    errors.append('Invalid time format for stopDateTime - "%r" - row %d' % (stop_time, index))

                if start_time == stop_time:
                    errors.append('Equivalent startDateTime and stopDateTime - (%r, %r) - row %d' %
                                  (start_time, stop_time, index))

                # reference designator must be valid. from ../../misc/reference_designators.csv
                if not record['Reference Designator'] in self.reference_designators:
                    errors.append('Reference Designator (%s) at csv index (%s) not in list of valid reference designators (./vocab/vocab.csv)' % (record['Reference Designator'], index+2))

                lat = record['lat']
                if not self.valid_float(lat):
                    errors.append('Invalid format for latitude - "%r" - row %d' % (lat, index))

                lon = record['lon']
                if not self.valid_float(lon):
                    errors.append('Invalid format for longitude - "%r" - row %d' % (lon, index))

                # depth = record['depth']
                # if not valid_float(depth):
                #     errors.append('Invalid format for depth - "%r" - row %d' % (depth, index))

            except AttributeError as e:
                errors.append('Deployment file is missing required fields: %s - row %d' % (e, index))
                break  # do not process the rest of the file

        return errors

    def test_deploy(self):
        """
        Cycle through all available deployment files and check
        """
        error_count = 0
        for root, dirs, files in os.walk(self.DEP_ROOT):
            for name in fnmatch.filter(files, '*.csv'):
                filename = os.path.join(root, name)
                errors = self.check_deploy_file(filename)
                if errors:
                    log.error('%s: %d error%s processing deployment file:', filename, len(errors),
                              '' if len(errors) == 1 else 's')
                    for error in errors:
                        log.error('    %s', error)
                    error_count += len(errors)

        self.assertEqual(error_count, 0, '%s errors encountered processing deployment files' % error_count)
