import logging
from collections import Counter

from dateutil import parser
from nose.plugins.attrib import attr

from ..test_base import AssetManagementUnitTest


@attr('UNIT')
class CruiseFileUnitTest(AssetManagementUnitTest):
    def test_times(self):
        errors = []
        for row in self.cruise_data.itertuples(index=False):
            try:
                parser.parse(row.cruiseStartDateTime)
                parser.parse(row.cruiseStopDateTime)
            except (ValueError, AttributeError):
                errors.append(row)
        self.assertEquals(errors, [], msg='Error parsing one or more times: %r' % errors)

    def test_duplicates(self):
        counter = Counter(self.cruise_data.CUID)
        duplicates = {k for k in counter if counter[k] > 1}
        self.assertEqual(duplicates, set(), msg='Found one or more duplicate cruise IDs: %r' % duplicates)
