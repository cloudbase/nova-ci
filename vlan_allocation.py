#!/usr/bin/env python

import sys
import MySQLdb
from MySQLdb.cursors import DictCursor
from optparse import OptionParser

parser = OptionParser(usage="usage: %prog [options] devstack_name")
parser.add_option("-a", "--allocate", action="store_false", default=True)
parser.add_option("-r", "--release", action="store_false", default=False)

(options, args) = parser.parse_args()

class VlanRanges(object):

    def __init__(self):
        self.db = MySQLdb.connect(
                host="10.13.1.27",
                user="jenkins-slave",
                passwd="cMo83Hdef8d",
                db="cbs_data",
                read_default_file="~/.my.cnf",
                cursorclass = DictCursor)
        self.conn = self.db.cursor()

    def get_range(self, devstack):
        # escape input
        name = self.db.escape_string(str(devstack))

        # Check if we already have a vlan range alocated for this devstack.
        # For situations where we execute this cript as part of an
        # exec_withretry block
        ret = self.conn.execute("""select * from vlanIds where devstack="%s";""" % name)
        if ret:
            row = self.conn.fetchone()
            return "%s:%s" % (row['vlanStart'], row['vlanEnd'])

        # Allocate new vlan range
        self.conn.execute("""start transaction;""")
        ret = self.conn.execute("""select * from vlanIds where devstack is NULL LIMIT 1 FOR UPDATE;""")
        if ret:
            row = self.conn.fetchone()
            update_ret = self.conn.execute("""update vlanIds set devstack="%s" where id='%s';""" % (name, row['id']))
            if update_ret == 0:
                self.conn.execute("""rollback;""")
                raise Exception("Failed to get range")
        self.conn.execute("""COMMIT;""")
        return "%s:%s" % (row['vlanStart'], row['vlanEnd'])

    def release_range(self, devstack):
        """ Release range associated to devstack """
        # escape input
        name = self.db.escape_string(str(devstack))
        ret = self.conn.execute("""select * from vlanIds where devstack="%s";""" % name)
        if ret == 0:
            return True

        # release range
        self.conn.execute("""start transaction;""")
        update_ret = self.conn.execute("""update vlanIds set devstack=NULL where devstack='%s';""" % name)
        if update_ret == 0:
            self.conn.execute("""rollback;""")
            raise Exception("Failed to get range")
        self.conn.execute("""COMMIT;""")
        return True


if __name__ == "__main__":
    parser = OptionParser(usage="usage: %prog [options] devstack_name")
    parser.add_option("-a", "--allocate", action="store_true", default=False)
    parser.add_option("-r", "--release", action="store_true", default=False)

    (options, args) = parser.parse_args()

    if options.allocate and options.release:
        parser.error("options -a and -r are mutually exclusive")

    if len(args) == 0:
        print("You must specify devstack name")
        sys.exit(1)

    ranges = VlanRanges()
    if options.allocate:
        print ranges.get_range(args[0])
    if options.release:
        ranges.release_range(args[0])
