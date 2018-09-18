#! /usr/bin/python

## Parse the apache log for specific details by conditional.
##  If no file is specified, it uses the most recent access log for the current userdir.
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
    logfile = "/var/log/nginx/"+user+".apachestyle.log"
except:
    pass

# #########
# log_format  notes
# apachestandard '$remote_addr $http_host $remote_user [$time_local] "$request"
#   $status $body_bytes_sent "$http_referer" "$http_user_agent"';
# #########

description_text = '''
 ....::::: Parse the apache log for specific details by conditional :::::....\
 no file is specified, uses the most recent access log from current directory.\
 Lower-case args specify output, Upper-case args specify filters.'''

# Setting up flags and help-text for specifying checks
parser = argparse.ArgumentParser(
   description=description_text,
   epilog="Email bugs/feature requests to alan.congleton@wpengine.com",
   formatter_class=lambda prog: argparse.HelpFormatter(prog,
                                                       max_help_position=30),
                                                       add_help=False)
parser.add_argument("--help",
                    help="Print Usage Info/Help",
                    action='store_true')
parser.add_argument("-i", "--find_ip",
                    help="Retrieve count of top IP addresses",
                    action='store_true')
parser.add_argument("-t", "--find_request",
                    help="Retrieve count of requests by type. (GET,POST,etc)",
                    action='store_true')
parser.add_argument("-r", "--find_response",
                    help="Retrieve count of server responses (200,404,etc)",
                    action='store_true')
parser.add_argument("-o", "--find_host",
                    help="Retrieve count of hostname requests.",
                    action="store_true")
parser.add_argument("-u", "--find_uri",
                    help="Retrieve count of request URIs.",
                    action="store_true")
parser.add_argument("-e", "--find_referer",
                    help="Retrieve count of HTTP referers.",
                    action="store_true")
parser.add_argument("-a", "--find_useragent",
                    help="Retrieve count of user agents.",
                    action="store_true")
parser.add_argument("-d", "--find_day",
                    help="Show requests per day.",
                    action="store_true")
parser.add_argument("-h", "--find_hour",
                    help="Show requests per hour.",
                    action="store_true")
parser.add_argument("-m", "--find_minute",
                    help="Show requests per minute.",
                    action="store_true")
parser.add_argument("-I", "--filter_ip",
                    help="IP address to limit the search to.",
                    dest="filter_ip",
                    metavar="")
parser.add_argument("-T", "--filter_request",
                    help="Request type to limit the search to.",
                    dest="filter_request",
                    metavar="")
parser.add_argument("-R", "--filter_response",
                    help="Response type to limit the search to.",
                    dest="filter_response",
                    metavar="")
parser.add_argument("-O", "--filter_host",
                    help="Hostname to limit search to.",
                    dest="filter_host",
                    metavar="")
parser.add_argument("-U", "--filter_uri",
                    help="Request URI to limit search to.",
                    dest="filter_uri",
                    metavar="")
parser.add_argument("-E", "--filter_referer",
                    help="HTTP Referer to limit search to.",
                    dest="filter_referer",
                    metavar="")
parser.add_argument("-A", "--filter_useragent",
                    help="User Agent to limit search to.",
                    dest="filter_useragent",
                    metavar="")
parser.add_argument("-D", "--filter_day",
                    help="Day to limit the search to.",
                    dest="filter_day",
                    metavar="")
parser.add_argument("-H", "--filter_hour",
                    help="Hour to limit search to.",
                    dest="filter_hour",
                    metavar="")
parser.add_argument("-M", "--filter_minute",
                    help="Minute to limit search to.",
                    dest="filter_minute",
                    metavar="")
parser.add_argument("-L", "--limit",
                    help="Limit the output to specified number of lines.",
                    dest="output_length",
                    default=20,
                    metavar="")
parser.add_argument("-F", "--file",
                    dest="log_file",
                    type=argparse.FileType('r'),
                    help="Specify the log file to use.",
                    metavar="")
parser.add_argument("-q", "--quiet",
                    dest="quiet_mode",
                    help="Quiet Mode. No summary is output.",
                    action='store_true')
parser.add_argument("--debug",
                    dest="debug",
                    help="Enable debug output for some things.",
                    action='store_true')
args = parser.parse_args()

# Print help if no arguments are supplied.
if (args.help):
    parser.print_help()
    sys.exit(1)

# If no flags specified, set some default ones and inform user about help info.
if not args.find_ip and not args.find_request and not args.find_response \
   and not args.find_host and not args.find_uri and not args.find_day \
   and not args.find_hour and not args.find_minute and not args.find_referer \
   and not args.find_useragent:
    print("\033[1;31mNo Arguments Supplied.\033[0m :: "
          "Running some basic checks.  Use \033[1m--help\033[0m"
          " for options. :3")
    args.find_ip = True
    args.find_request = True
    args.find_response = True
    args.find_host = True
    args.find_uri = True


# Check if file is specified, check to see if it was set, exiting if not set
try:
    logfile = args.log_file.name
except:
    try:
        logfile
    except:
        print("\033[1;31mLogfile not specified or not in a user's "
              "home directory.  Exiting.\033[0m")
        sys.exit(1)

# Declare some blank dictionaries for holding the values.
ip = {}
request = {}
uri = {}
response = {}
host = {}
referer = {}
useragent = {}
day = {}
hour = {}
minute = {}


if logfile.endswith(".gz"):
    import gzip
    log = gzip.open(logfile, 'r')
else:
    try:
        log = open(logfile, 'r')
    except:
        print("\033[1;31mERR: Logfile \033[0m"+logfile +
              "\033[1;31m not found.\033[0m :<")
        sys.exit(1)

log_length = 0

# Lets get to parsing them lines into arrays!
for line in log:
  log_length += 1
  raw_line = line
  line = re.split(' |"', line)
  time = re.split('/|:', line[3])
  time[0] = re.sub('\[', '', time[0])  # remote preceeding [ from day
  # UserAgent gets split up because of spaces, but it's at end of the line
  # :D (-1 to omit newline)
  line[16] = ' '.join(line[16:-1])
  try:  # In case of any oddities in the log line, it will pass on that line.
     if ((args.filter_ip is not None and re.search(args.filter_ip, line[0]) is not None) or args.filter_ip is None) \
      and ((args.filter_request is not None and re.search(args.filter_request, line[6]) is not None) or args.filter_request is None)\
      and ((args.filter_response is not None and re.search(args.filter_response, line[10]) is not None) or args.filter_response is None)\
      and ((args.filter_host is not None and re.search(args.filter_host, line[1]) is not None) or args.filter_host is None)\
      and ((args.filter_uri is not None and re.search(args.filter_uri, line[7]) is not None) or args.filter_uri is None)\
      and ((args.filter_referer is not None and re.search(args.filter_referer, line[13]) is not None) or args.filter_referer is None)\
      and ((args.filter_useragent is not None and re.search(args.filter_useragent, line[16]) is not None) or args.filter_useragent is None)\
      and ((args.filter_day is not None and re.search(args.filter_day, time[0]) is not None) or args.filter_day is None)\
      and ((args.filter_hour is not None and re.search(args.filter_hour, time[3]) is not None) or args.filter_hour is None)\
      and ((args.filter_minute is not None and re.search(args.filter_minute, time[4]) is not None) or args.filter_minute is None):

        if args.find_ip:
            if line[0] in ip:
                ip[line[0]] += 1
            else:
                ip[line[0]] = 1

        if args.find_host:
            if line[1] in host:
                host[line[1]] += 1
            else:
                host[line[1]] = 1

        if args.find_request:
            if line[6] in request:
                request[line[6]] += 1
            else:
                request[line[6]] = 1

        if args.find_uri:
            if line[7] in uri:
                uri[line[7]] += 1
            else:
                uri[line[7]] = 1

        if args.find_response:
            if line[10] in response:
                response[line[10]] += 1
            else:
                response[line[10]] = 1

        if args.find_referer:
            if line[13] in referer:
                referer[line[13]] += 1
            else:
                referer[line[13]] = 1

        if args.find_useragent:
            if line[16] in useragent:
                useragent[line[16]] += 1
            else:
                useragent[line[16]] = 1

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
  except:
    if args.debug:
        print "Debug: " + raw_line
    else:
        pass  # In case of line derpage.

log.closed

# Print Summary
if not args.quiet_mode:
    summary = "\033[4;32m _ _ _ _ Summary _ _ _ _ \033[0m\n" + \
              " Lines Parsed:\t"+str(log_length)
    print "\033[1;32mSearching:\033[0;32m " + logfile
    filters = ''
    if (args.filter_ip is not None):
        filters = filters+"\033[1;32mFilter IP:\033[0;32m    " + \
                   args.filter_ip + "\n"
    if (args.filter_request is not None):
        filters = filters + "\033[1;32mRequest Type:\033[0;32m " + \
                   args.filter_request + "\n"
    if (args.filter_response is not None):
        filters = filters + "\033[1;32mResponse:\033[0;32m     " + \
                 args.filter_response + "\n"
    if (args.filter_host is not None):
        filters = filters + "\033[1;32mHostName:\033[0;32m     " + \
                   args.filter_host + "\n"
    if (args.filter_uri is not None):
        filters = filters + "\033[1;32mRequest URI:\033[0;32m  " + \
                   args.filter_uri + "\n"
    if (args.filter_referer is not None):
        filters = filters + "\033[1;32mHTTP Referer:\033[0;32m  " + \
                   args.filter_referer + "\n"
    if (args.filter_useragent is not None):
        filters = filters + "\033[1;32mUser Agent:\033[0;32m  " + \
                   args.filter_useragent + "\n"
    if (args.filter_day is not None):
        filters = filters + "\033[1;32mDay:\033[0;32m " + \
                   args.filter_day + "\033[0m | "
    if (args.filter_hour is not None):
        filters = filters + "\033[1;32mHour:\033[0;32m " + \
                   args.filter_hour + "\033[0m | "
    if (args.filter_minute is not None):
        filters = filters + "\033[1;32mMinute:\033[0;32m " + \
                   args.filter_minute
    print filters + "\033[0m"

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
    if args.find_referer:
        summary = summary+"\n HTTP Referers:\t"+str(len(referer))
    if args.find_useragent:
        summary = summary+"\n User Agents:\t"+str(len(useragent))
    print summary+"\n"

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

# Print results of the Referer dict
if args.find_referer:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "HTTP Referer"))
    for i in sorted(referer, key=referer.get, reverse=True):
        if count < int(args.output_length):
            print("%10s  %-s" % (referer[i], i))
            count += 1
        else:
            break

# Print results of the useragent dict
if args.find_useragent:
    count = 0
    print("\033[4;32m%10s  %-30s\033[0m" % ("Count", "User Agent"))
    for i in sorted(useragent, key=useragent.get, reverse=True):
        if count < int(args.output_length):
            print("%10s  %-s" % (useragent[i], i))
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
