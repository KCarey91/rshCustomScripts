#! /usr/bin/python
## Sifts through all vailable logs in /var/log/apache2/error.log* for
##   Segfaults, Restarts, Reloads, SIGTERMs
## Then prints off the results in a table for easy reading.
##  Useful for diagnosing random 502s
from glob import glob
import gzip

logs = glob('/var/log/apache2/error.log*')
logs.sort()
print '\033[4m{:20s} | {:>10s} | {:>10s} | {:>10s} | {:>10s} | {:>10s}\033[0m'.format('LogFile','SegFault','Restart','Reload','SIGTERM','Total Lines')

for logfile in logs:
    seg = 0
    restart = 0
    relo = 0
    sigterm = 0
    lines = 0
    if logfile.endswith(".gz"):
        log = gzip.open(logfile, 'r')
    else:
        log = open(logfile, 'r')
    for line in log:
        if 'Segmentation' in line:
            seg += 1
        elif "restart" in line:
            restart += 1
        elif "reload" in line:
            relo += 1
        elif "SIGTERM" in line:
            sigterm += 1
        lines += 1
    print '{:20s} | {:10d} | {:10d} | {:10d} | {:10d} | {:10d}'.format(logfile.split('/')[-1],seg,restart,relo,sigterm,lines)
