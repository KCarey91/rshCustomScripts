#! /bin/bash
## Rewrite of a trick to catch and trace a request made to Apache that I got initially from Hogan
## Run from home dir of installation, append ?meow to the end.  Alternately, add an argument for the
##  hook to look for in the URL.
## eg:  catch_trace wp-admin

catch_trace() {
  [[ -n $1 ]] && hook=$1 || hook=meow
  ( install=$(pwd|cut -d/ -f5)
  domain="$(grep wpe_all_domains wp-config.php | grep -oP "(?<==> ')[^']*" | tr '\n' '|')${install}.staging.wpengine.com"
  myip=66.162.212.19
  echo $domain
  while true; do
    lynx -dump -width 480 http://0:6789/sd_apache_status 2>&1 | egrep "(${myip}|127.0.0.1).*(${domain}${install}).*meow" |
      awk '{if ($6 < '2') printf "strace -vvtf -s 1024 -p %s\n", $2}'| bash
    sleep 0.1
  done ) 2>&1 |grep -v gettimeofday | tee _wpeprivate/strace.log
}
