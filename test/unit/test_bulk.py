import csv
import glob
import logging
from collections import Counter

from nose.plugins.attrib import attr

from test.test_base import AssetManagementUnitTest

logging.basicConfig()
log = logging.getLogger()
log.setLevel(logging.INFO)


@attr('UNIT')
class BulkLoadUnitTest(AssetManagementUnitTest):
    def test_duplicate_uid(self):
        counter = Counter(self.bulk_data.uid.values)
        counter.subtract(set(self.bulk_data.uid.values))
        dupes = counter + Counter()
        if dupes:
            log.error('Found duplicate keys in bulk load: %r', dupes)
            assert False

    def test_col_count(self):
        for filename in glob.glob(self.BULK_FILES_GLOB):
            with open(filename) as fh:
                reader = csv.reader(fh)
                header = next(reader)
                for row in reader:
                    self.assertEqual(len(header), len(row))