#! /usr/bin/python
# coding=UTF-8

import sys
import os
import ConfigParser
import requests
import json


def print_help():
    print '''
    Used to print off some useful information about the total disk usage of an account across all installations.
    It also further breaks down the usage by showing what percent of total usage is used by each install, and by pod.
    Must be run from a pod in order to pull the API key properly.

    Usage:
      install-disk-usage <install>   ::  Perform check for <install>
      install-disk-usage --help      ::  Print this message.  :3

    Example Output:
    user1 (comped) Disk: 30GB / BW: 30GB
    user2 user3

    Disk TOTAL           ░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 0.244140625%   ( 75 / 30720 MB )

    Pod/Install          % of total disk
    pod-69               ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓ 100.0%   ( 75 MB )
      user1              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 34.6666666667%   ( 26 MB )
      user2              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 33.3333333333%   ( 25 MB )
      user3              ▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 30.6666666667%   ( 23 MB )
    '''
    exit()

# maybe add some help text on failure to supply an argument.
try:
    sys.argv[1]
except:
    print_help()
    exit()

if sys.argv[1] == "--help":
    print_help()
else:
    install = sys.argv[1]


#  Get API Key
if os.path.isfile(os.path.expanduser('/etc/wpengine/wpe.cnf')):  # pod
    apiconf = os.path.expanduser('/etc/wpengine/wpe.cnf')
else:
    print '''
    No API key found.  Exiting.  Use --help
    '''
    exit()

config = ConfigParser.ConfigParser()
config.read(apiconf)
wpeapikey = config.get('admin_keys', '0')

# Using the supplied installation, get the parent account and child accounts.
#  Concatenate into a full list as well.  eg:
# {"parent":"eremite","children":["eremitestaging","erutest","erums","erutransfer"]}

parent_child_url = 'https://api.wpengine.com/account/family.php?wpe_apikey=' +\
                     wpeapikey+'&account='+install
install_list = requests.get(parent_child_url).json()
parent_install = install_list['parent']
child_installs = install_list['children']
install_list = [parent_install]+child_installs

#  Pull Customer Records and define plan type and bandwidth/disk limitations:
record_url = 'https://api.wpengine.com/1.2/?method=customer-record&account_name=' +\
               parent_install+'&wpe_apikey='+wpeapikey
records = requests.get(record_url).json()
try:
    plan_type = records['plan']
    disk_limit = records['base_storage_gb']
    bandwidth_limit = records['base_bw_gb']
except:
    print "Failed to get plan information! The account probably doesn't exist."
    exit()

# Fix the incorrect disk usage that pops up frequently.
if plan_type == "business":
    disk_limit="30"
if plan_type == "professional":
    disk_limit="20"
if plan_type == "personal":
    disk_limit="10"
if disk_limit=="0":
    disk_limit="1"

#  Print parent, plan type, disk/bandwidh limits, followed by child installs:
# eg:
# eremite (comped) Disk: 30GB / BW: 30GB
# eremitestaging erutest erums erutransfer
print "\033[1;35m" + str(parent_install) + " \033[1;36m(" + plan_type + \
      ") Disk: " + disk_limit+"GB / BW: "+bandwidth_limit+"GB\033[0m"
print "\033[0;35m" + ' '.join(child_installs) + "\033[0m"


def get_option(option, install):  # pull an option value for a provided install
    option_url = 'https://api.wpengine.com/admin/1/index.php?method=config-option&option=' + \
                option+'&wpe_apikey='+wpeapikey+'&account='+install
    reply = requests.get(option_url).json()
    try:
        return str(reply['message'])
    except:
        return 0


def disk_usage(install):
    disk_usage_url = 'https://api.wpengine.com/1.2/index.php?method=disk-usage&account_name=' +\
                    install+'&wpe_apikey='+wpeapikey+'&blog_id=all'
    disk_usage = requests.get(disk_usage_url).json()
    # fix a problem where '0' key doesn't exist if it's a newly made install
    try:
        disk_usage = int(disk_usage['0']['kbytes'])
    except:
        disk_usage = -1
    return disk_usage


def bargraph(percent, width=50):
    bg_filled = '▓'
    bg_empty = '░'
    base_graph = '░' * width
    print base_graph.replace(bg_empty, bg_filled, int(percent/(100.0/width))),\
        "{:>7.2f}".format(percent) + " %",

    return ''

# Yo dawg, I heard you like dictionaries.
#  Make dict with grandtotal, nested dictionary, with install-specific counts.
# EG: {'40707': {'total': 77620, u'eremite': 27080}, 'grandtotal': 77620}
cluster_map = dict()
cluster_map['grandtotal'] = 0
current = 0
for install in install_list:
    # Progress bar for long checks:
    sys.stdout.write('\r '+str(bargraph(100.0*current/len(install_list)))+'\r')
    sys.stdout.flush()
    current += 1
    # The actual dictionary building
    cluster = get_option("cluster", install)
    cluster_map.setdefault(cluster, {'total': 0})
    try:
        disabled = get_option("disable", install)  # If it fails, no option set
    except:
        disabled = 0  # If no option set, it's never been disabled. Set to 0.
    if disabled == 0:
        install_usage = disk_usage(install)
        cluster_map[cluster]['total'] += install_usage
        cluster_map['grandtotal'] += install_usage
        cluster_map[cluster][install] = install_usage

# DEBUG
# print cluster_map

# PARSE SOME STUFF
# Print off the grand total account usage. (Grand total/plan limit)
grandtotal = int(cluster_map.pop("grandtotal")) / 1024
grandpct = grandtotal / (int(disk_limit) * 1024.0) * 100
print "Disk TOTAL".ljust(20),
bargraph(grandpct, 50)
print '  (', str(grandtotal), '/', str(int(disk_limit)*1024) + " MB )"

# Print col header for individual pods/installs & disk usage as an explanation
print '\n\033[4m'+'Pod/Install'.ljust(20), "% of total disk\033[0m",

# Sort the cluster_map dictionary so first items are smallest.
sorted_map = sorted(cluster_map,
                    key=lambda d: cluster_map.get(d, {}).get('total'),
                    reverse=True)

# Print and Graph all the things!
for cluster in sorted_map:
    if (len(cluster_map[cluster]) > 1):
        total = cluster_map[cluster].pop("total") / 1024
        print '\n'+('pod-'+str(cluster)).ljust(20),
        if (total == -1):
            print "?"*20+" UNKNOWN "+"?"*21
        else:
            bargraph(100.0 * total / grandtotal)
            print '  ( ' + str(total) + " MB )"
        for install in sorted(cluster_map[cluster],
                              key=cluster_map[cluster].get,
                              reverse=True):
            itotal = cluster_map[cluster][install]/1024
            print('  '+install).ljust(20),
            if (itotal == -1):
                print "?"*20+" UNKNOWN "+"?"*21
            else:
                bargraph(100.0 * itotal / grandtotal),
                print '  ( ' + str(itotal) + ' MB )'
