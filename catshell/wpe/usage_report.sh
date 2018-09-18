#! /bin/bash

## Prints off a *LOT* of usage information about a pod for upgrade/downgrade tickets.
##  Covers most of the content of the "Fact Finding" macro in ZenDesk.
##  Also, run a NoVa and link it in ticket. :)

function usage_report() {
  sudo cat FGSFDS &>/dev/null # get sudo password out of the way
  echo -e '```'
  awk 'BEGIN {print "===CPU INFO==="} ; /model name/ {cores+=1;if (x!=1) {print; x=1}};END{print "Cores : ",cores,"\n"}' /proc/cpuinfo
  sarqh
  echo -e '```\nMemory:\n\n```'
  free -m
  sarrh
  echo -e '```\nDisk:\n\n```'
  df -h /nas
  echo
  du -sh /nas/content/{live,staging}/* | sort -rh | head -n 20
  echo -e '```\nCluster Info:\n\n```'
  grep '' /etc/cluster-*
  egrep "(dbmaster|pub-dbmaster|pub-web)-$(cat /etc/cluster-id)" /etc/hosts
  echo -e '```\nMySQL Stats/Info:\n\n```\nSlow Queries:'
  sudo cat /var/log/mysql/mysql-slow.log | pt-query-digest
  echo -e "Top MySQL Database Sizes:"
  for i in $(ls /nas/content/live) ; do sudo du -sh /var/lib/mysql/{wp,snapshot}_${i} 2>/dev/null ; done | sort -rh | head -n 20
  echo -e '```'
}
