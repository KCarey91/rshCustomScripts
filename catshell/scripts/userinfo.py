#! /usr/bin/python
# coding=UTF-8
import os
import sys
import ConfigParser
import requests
import json


def print_help():
    print '''
    This pulls some useful information for an account provided.
    Usage:  userinfo <install_name>
    '''
    exit()

try:
    sys.argv[1]
except:
    print_help()
    exit()

if sys.argv[1] == "--help":
    print_help()
else:
    install = sys.argv[1]


# get wpeapi key
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

parent_child_url = 'https://api.wpengine.com/account/family.php?wpe_apikey=' +\
                    wpeapikey+'&account='+install
install_list = requests.get(parent_child_url).json()
parent_install = install_list['parent']
child_installs = install_list['children']
install_list = [parent_install]+child_installs

# Pull Customer Records & define the plan type and bandwidth/disk limitations:
record_url = 'https://api.wpengine.com/1.2/?method=customer-record&account_name=' +\
              parent_install+'&wpe_apikey='+wpeapikey
records = requests.get(record_url).json()

debug = 0
if debug == 1:
    for i in records:
        print "\033[1;36m", i, "\033[0m: ", records[i]

try:
    plan_type = records['plan']
    disk_limit = records['base_storage_gb']
    bandwidth_limit = records['base_bw_gb']
    owner_name = records['full_name']
    owner_email = records['email']
except:
    print "Failed to get plan information! The account probably doesn't exist."
    exit()

# Some colory-things to make the output pretty.
if (int(records["balance_pastdue"]) > 0):
    records["balance_pastdue"] = "\033[1;31m" + \
                                 str(records["balance_pastdue"]) + "\033[0m"

if (len(child_installs) > int(records["max_domains"])):
    records["max_domains"] = "\033[1;31m" + records["max_domains"] + \
                               " (Possibly Over Limit)\033[0m"

if (records["risk_level"] == "Green"):
    records["risk_level"] = "\033[1;32m" + records["risk_level"] + "\033[0m"
elif (records["risk_level"] == "Yellow"):
    records["risk_level"] = "\033[1;33m" + records["risk_level"] + "\033[0m"
elif (records["risk_level"] == "Red"):
    records["risk_level"] = "\033[1;31m" + records["risk_level"] + "\033[0m"
elif (records["risk_level"] is None or records["risk_level"] == "Unknown"):
    records["risk_level"] = "\033[1;30m"+str(records["risk_level"])+"\033[0m"

# Print off the results.
print ""
print "\033[4m\033[1mAccount Info\033[0m"
print "\033[1mParent Install :\033[0m", parent_install, "ID:" + records["install_id"]
print '\033[1mPlan Type      :\033[0m', plan_type
print "\033[1mDisk/BW Limits :\033[0m", disk_limit + "GB / " + \
      bandwidth_limit + "GB"
print "\033[1mMax Domains    :\033[0m", records['max_domains']
print "\033[1mChildren (" + str(len(child_installs)) + "): \033[0m", \
      ' '.join(child_installs)
print ''
print "\033[4m\033[1mOwner Info\033[0m"

# Set the relevant records and then loop through them to display.
relevant_records = "full_name customer_id email phone created_on "\
                 "account_manager account_owner base_rate annual_revenue "\
                  "balance_pastdue risk_level"
for record in relevant_records.split(' '):
    print "\033[1m" + str(record) + "\033[0m: " + str(records[record])
