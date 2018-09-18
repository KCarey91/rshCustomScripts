#!/bin/bash

## Prints off the top installs for CPU Hours consumed as tallied from upstream time in the Nginx logs.
##  Also prints off the total hits that they have to the apache log.
##
##  Usage:  atop (file_extension)   ||  eg:   atop  //  atop .1  (for access.log.1) // atop .2.gz for access.log.2.gz // etc

function atop() {
  __extension=$1
  if [[ $__extension =~ (^$|\.1|\.[2-9]\.gz) ]] ; then
    ( echo -e "CPU_Seconds User ApacheHits"
    if [[ $__extension =~ [2-9]\.gz ]] ; then
      for i in $(ls /nas/content/live/) ; do
          echo -e "$(zcat /var/log/nginx/${i}.access.log${__extension} 2>/dev/null | awk -F"|" '{total=total+$9} ; END {printf total}' 2>/dev/null) ${i} $(zcat /var/log/apache2/${i}.access.log${__extension} 2>/dev/null| wc -l 2>/dev/null | awk '{print $1}')"
      done
    else
      for i in $(ls /nas/content/live/) ; do
          echo -e "$(awk -F"|" '{total=total+$9} ; END {printf total}' /var/log/nginx/${i}.access.log${__extension} 2>/dev/null) ${i} $(wc -l /var/log/apache2/${i}.access.log${__extension} 2>/dev/null | awk '{print $1}')"
      done
    fi | sort -rn | head -n 30 ) | column -t
  else
    echo "Invalid extension. Must be .1 or .2.gz -> .9.gz"
  fi
  unset __extension
}
