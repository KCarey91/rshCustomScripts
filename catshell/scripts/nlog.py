#! /usr/bin/python

## Parse the nginx log for specific details by conditional.
##  If no file is specified, it uses the most recent access log for the current userdir.
##  If no flags are provided, it assumes: ip, request type, response type, URI, hostname.
##
##  Flag Conventions:
##    Lowercase flags will specify what the output will be.  (eg: -i for IP count)
##    Uppercase flags filter output by provided arguments.   (eg -I 127.0.0.1 )
##
##  Tip : Need to search all the logs for something specific?
##   zgrep the desired logs with the -h flag to leave out the leading filename.
##   > redirect that to a file, then specify that file with the -F flag.
##
##  Use --help for flag info.  There's a lot of flags.

import sys
import os
import re
import socket
import argparse

# Set niceness level to 19 to avoid overusing CPU resources.
#  This all runs on a single core anyway, but nicer is better.
os.nice(19)

# Get the user from PWD if possible and declare logfile var.
try:
    user = re.split("/", os.getcwd())[4]
    logfile = "/var/log/nginx/"+user+".access.log"
except:
    pass

# log_format  notes
# $time_local|v1|$remote_addr|$http_host|$status|$body_bytes_sent|$upstream_addr|$upstream_response_time|$request_time|$request
#
# TO DO:
#  Top File hits (ignoring query string)
#  Fuzzy matching for URI filter.  (either regex or partial match)
# #########

description_text = ''' .....::::: Parse the nginx log for specific details by conditional :::::.....\
                 If no file is specified, uses the most recent access log from current user directory.\
                 Lower-case args specify output, Upper-case args specify filters.'''

# Setting up flags and help-text for specifying checks
parser = argparse.ArgumentParser(description=description_text, epilog="Email bugs/feature requests to alan.congleton@wpengine.com",
                                 formatter_class=lambda prog: argparse.HelpFormatter(prog, max_help_position=30), add_help=False)
parser.add_argument("--help", help="Print Usage Info/Help", action='store_true')
parser.add_argument("-i", "--find_ip", help="Retrieve count of top IP addresses", action='store_true')
parser.add_argument("-t", "--find_request", help="Retrieve count of requests by type. (GET,POST,etc)", action='store_true')
parser.add_argument("-r", "--find_response", help="Retrieve count of server responses (200,404,etc)", action='store_true')
parser.add_argument("-o", "--find_host", help="Retrieve count of hostname requests.", action="store_true")
parser.add_argument("-u", "--find_uri", help="Retrieve count of request URIs.\n\n", action="store_true")
parser.add_argument("-w", "--find_wait", help="Retrieve longest-running processes (longest wait)", action='store_true')
parser.add_argument("-d", "--find_day", help="Show requests per day.", action="store_true")
parser.add_argument("-h", "--find_hour", help="Show requests per hour.", action="store_true")
parser.add_argument("-m", "--find_minute", help="Show requests per minute.", action="store_true")
parser.add_argument("-I", "--filter_ip", help="IP address to limit the search to.", dest="filter_ip", metavar="")
parser.add_argument("-T", "--filter_request", help="Request type to limit the search to.", dest="filter_request", metavar="")
parser.add_argument("-R", "--filter_response", help="Response type to limit the search to.", dest="filter_response", metavar="")
parser.add_argument("-O", "--filter_host", help="Hostname to limit search to.", dest="filter_host", metavar="")
parser.add_argument("-U", "--filter_uri", help="Request URI to limit search to.", dest="filter_uri", metavar="")
parser.add_argument("-W", "--filter_wait", help="Find requests longer than N wait time.", dest="filter_wait", metavar="")
parser.add_argument("-D", "--filter_day", help="Day to limit the search to.", dest="filter_day", metavar="")
parser.add_argument("-H", "--filter_hour", help="Hour to limit search to.", dest="filter_hour", metavar="")
parser.add_argument("-M", "--filter_minute", help="Minute to limit search to.", dest="filter_minute", metavar="")
parser.add_argument("-L", "--limit", help="Limit the size of the output to a specified number of lines.", dest="output_length", default=20, metavar="")
parser.add_argument("-F", "--file", dest="log_file", type=argparse.FileType('r'), help="Specify the log file to use.", metavar="")
parser.add_argument("-q", "--quiet", dest="quiet_mode", help="Quiet Mode. No summary is output.", action='store_true')
parser.add_argument("--debug", dest="debug", help="Enable debug output for some things.", action='store_true')
args = parser.parse_args()

# Print help if no arguments are supplied.

if (args.help):
    parser.print_help()
    sys.exit(1)

# If no find flags are specified, set some default ones and inform user about help info.
if not args.find_ip and not args.find_request and not args.find_response and not args.find_host and not args.find_uri\
  and not args.find_wait and not args.find_day and not args.find_hour and not args.find_minute:
    print("\033[1;31mNo Arguments Supplied.\033[0m :: Running some basic checks.  Use \033[1m--help\033[0m for options. :3")
    args.find_ip = True
    args.find_request = True
    args.find_response = True
    args.find_host = True
    args.find_uri = True


# Check to see if file is redeclared via CLI, else check to see if it was set, exiting if not with message.
try:
    logfile = args.log_file.name
except:
    try:
        logfile
    except:
        print("\033[1;31mLogfile not specified or not in a user's home directory.  Exiting.\033[0m")
        sys.exit(1)

# Declare some blank dictionaries for holding the values.
ip = {}
request = {}
uri = {}
response = {}
host = {}
wait = {}
day = {}
hour = {}
minute = {}
upstream = {}
# Total count for upstream, plus apache/varnish/statics
upstream[0] = 0
upstream["127.0.0.1:9002"] = 0
upstream["127.0.0.1:6776"] = 0
upstream["127.0.0.1:6788"] = 0
upstream["127.0.0.1:6789"] = 0
upstream["-"] = 0


if logfile.endswith(".gz"):
    import gzip
    log = gzip.open(logfile, 'r')
else:
    try:
        log = open(logfile, 'r')
    except:
        print("\033[1;31mERR: Logfile \033[0m"+logfile+"\033[1;31m not found.\033[0m :<")
        sys.exit(1)

log_length = 0

for line in log:
  log_length += 1
  raw_line = line
  line = re.split(' |\|', line)
  time = re.split(":|/", line[0])
  try:  # This fixes an error in -secure.access.log where request info is blank (-), breaking arrays.
     if ((args.filter_ip is not None and re.search(args.filter_ip, line[3]) is not None) or args.filter_ip is None) \
      and ((args.filter_request is not None and re.search(args.filter_request, line[10]) is not None) or args.filter_request is None)\
      and ((args.filter_response is not None and re.search(args.filter_response, line[5]) is not None) or args.filter_response is None)\
      and ((args.filter_host is not None and re.search(args.filter_host, line[4]) is not None) or args.filter_host is None)\
      and ((args.filter_uri is not None and re.search(args.filter_uri, line[11]) is not None) or args.filter_uri is None)\
      and (line[9] > args.filter_wait or args.filter_wait is None)\
      and ((args.filter_day is not None and re.search(args.filter_day, time[0]) is not None) or args.filter_day is None)\
      and ((args.filter_hour is not None and re.search(args.filter_hour, time[3]) is not None) or args.filter_hour is None)\
      and ((args.filter_minute is not None and re.search(args.filter_minute, time[4]) is not None) or args.filter_minute is None):

        if args.find_ip:
            if line[3] in ip:
                ip[line[3]] += 1
            else:
                ip[line[3]] = 1

        if args.find_host:
            if line[4] in host:
                host[line[4]] += 1
            else:
                host[line[4]] = 1

        if args.find_request:
            if line[10] in request:
                request[line[10]] += 1
            else:
                request[line[10]] = 1

        if args.find_uri:
            if line[11] in uri:
                uri[line[11]] += 1
            else:
                uri[line[11]] = 1

        if args.find_response:
            if line[5] in response:
                response[line[5]] += 1
            else:
                response[line[5]] = 1

        if args.find_wait:
            if (len(wait) < args.output_length or float(line[9]) > float(sorted(wait, reverse=True)[-1])):
                # print line[9], sorted(wait,reverse=True)[:] #debug
                wait[line[9]] = line
            if (len(wait) > args.output_length):
                del wait[sorted(wait, reverse=True)[-1]]

        if args.find_day:
            if time[0] in day:
                day[time[0]] += 1
            else:
                day[time[0]] = 1

        if args.find_hour:
            if time[3] in hour:
                hour[time[3]] += 1
            else:
                hour[time[3]] = 1

        if args.find_minute:
            if time[4] in minute:
                minute[time[4]] += 1
            else:
                minute[time[4]] = 1

        try:
            upstream[line[7]] += 1
        except:
            upstream[line[7]] = 1
        upstream[0] += 1
  except:
      if args.debug:
        print "Debug: " + raw_line
      else:
        pass  # This fixes an error in -secure.access.log where request info is blank (-), breaking arrays.


log.closed

# Print Summary
if not args.quiet_mode:
    summary = "\033[4;32m _ _ _ _ Summary _ _ _ _ \033[0m\n Lines Parsed:\t"+str(log_length)
    apache_total = upstream["127.0.0.1:6776"] + upstream["127.0.0.1:6788"] + upstream["127.0.0.1:6789"]
    summary = summary+"\n Varnish Pass:  " + str(upstream["127.0.0.1:9002"]) + "\n Apache Pass :  "+str(apache_total)+"  (RW:"+str(upstream["127.0.0.1:6788"])+"  R: "+str(upstream["127.0.0.1:6789"])+"  Q: " + str(upstream["127.0.0.1:6776"]) + ")\n Static Hits :  "+str(upstream["-"])
    print("\033[1;32mSearching:\033[0;32m " + logfile)
    filters = ''
    if (args.filter_ip is not None):
        filters = filters+"\033[1;32mFilter IP:\033[0;32m    " + args.filter_ip + "\n"
    if (args.filter_request is not None):
        filters = filters + "\033[1;32mRequest Type:\033[0;32m " + args.filter_request + "\n"
    if (args.filter_response is not None):
        filters = filters + "\033[1;32mResponse:\033[0;32m     " + args.filter_response + "\n"
    if (args.filter_host is not None):
        filters = filters + "\033[1;32mHostName:\033[0;32m     " + args.filter_host + "\n"
    if (args.filter_uri is not None):
        filters = filters + "\033[1;32mRequest URI:\033[0;32m  " + args.filter_uri + "\n"
    if (args.filter_day is not None):
        filters = filters + "\033[1;32mDay:\033[0;32m " + args.filter_day + "\033[0m | "
    if (args.filter_hour is not None):
        filters = filters + "\033[1;32mHour:\033[0;32m " + args.filter_hour + "\033[0m | "
    if (args.filter_minute is not None):
        filters = filters + "\033[1;32mMinute:\033[0;32m " + args.filter_minute
    print(filters + "\033[0m")

    if args.find_ip:
        summary = summary+"\n IP Addresses:\t"+str(len(ip))
    if args.find_host:
        summary = summary+"\n Hostnames:\t"+str(len(host))
    if args.find_request:
        summary = summary+"\n Request Types:\t"+str(len(request))
    if args.find_uri:
        summary = summary+"\n Request URIs:\t"+str(len(uri))
    if args.find_response:
        summary = summary+"\n Response Code:\t"+str(len(response))
    print(summary+"\n")
# len(ip),"IPs",len(host),"hosts |",len(request),"request types"

# Print results of the IP address dict
if args.find_ip:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "IP Address"))
    for i in sorted(ip, key=ip.get, reverse=True):
        if count < int(args.output_length):
            try:
                RDNS = socket.gethostbyaddr(i)[0]
            except:
                RDNS = "--Not-Found--"
            print("%10s  %-15s  %-s" % (ip[i], i, RDNS))
            count += 1
        else:
            break

# Print results of host dict

if args.find_host:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Hostname"))
    for i in sorted(host, key=host.get, reverse=True):
        if count < int(args.output_length):
            print("%10s  %-s" % (host[i], i))
            count += 1
        else:
            break

# Print results of the Requests dict
if args.find_request:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Request Type"))
    for i in sorted(request, key=request.get, reverse=True):
        if count < int(args.output_length):
            print("%10s  %-s" % (request[i], i))
            count += 1
        else:
            break

# Print results of the URI dict
if args.find_uri:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Request URI"))
    for i in sorted(uri, key=uri.get, reverse=True):
        if count < int(args.output_length):
            print("%10s  %-s" % (uri[i], i))
            count += 1
        else:
            break

# Print results of the Response dict
if args.find_response:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Response Code"))
    for i in sorted(response, key=response.get, reverse=True):
        if count < int(args.output_length):
            print("%10s  %-s" % (response[i], i))
            count += 1
        else:
            break

# Print results of the day dict
if args.find_day:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Day"))
    for i in sorted(day):
        if count < int(args.output_length):
            print("%10s  %-s" % (day[i], i))
            count += 1
        else:
            break

# Print results of the Hour dict
if args.find_hour:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Hour"))
    for i in sorted(hour):
        if count < int(args.output_length):
            print("%10s  %-s" % (hour[i], i))
            count += 1
        else:
            break

# Print results of the Minute dict
if args.find_minute:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "Minute"))
    for i in sorted(minute):
        if count < int(args.output_length):
            print("%10s  %-s" % (minute[i], i))
            count += 1
        else:
            break

# Print results of the wait dict last because it's full lines
if args.find_wait:
    print("\033[4;32m%s\033[0m" % ("Full lines for longest wait times:"))
    for i in sorted(wait, reverse=True):
        sys.stdout.write(' '.join(wait[i]))
