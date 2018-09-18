#!/bin/bash
## Runs a check on all sites to see individual site cacheability
##   and an over-all server cacheability for fact-finding.
##
## Static files are excluded from nginx totals.
##        100 - 100 * APACHE_HITS/NON_STATIC_NGINX_HITS %
##
##   Usage:  cacheability_check -s (suffix) {optional list of installs}
##      eg:  cacheability_check -s .1 install1  install2 install3
##   -s flag must come BEFORE list of installs.
##

function cacheability_check() {
  OPTIND=1
  while getopts "s:" opt ; do
    case ${opt} in
      s) __suffix=${OPTARG} ;;
    esac
  done
  shift $((OPTIND-1))

  if [[ -n ${*} ]] ; then
    __install_list=${*}
  else
    __install_list=$(ls /var/log/nginx/*.access.log 2>/dev/null|egrep -v "(secure.access.log|apache-queue.access.log)" | grep -oP '(?<=nginx/)[^.]*')
  fi

  static_regex='/favicon\.|/apple-touch-icon[^/]*\.png|/crossdomain\.xml|/(wp-content/(themes|plugins|uploads|wptouch-data|gallery)|wp-includes|wp-admin)/.*\.(jpe?g|gif|png|css|js|ico|zip|7z|tgz|gz|rar|bz2|do[ct][mx]?|xl[ast][bmx]?|exe|pdf|p[op][ast][mx]?|sld[xm]?|thmx?|txt|tar|midi?|wav|bmp|rtf|avi|mp\d|mpg|iso|mov|djvu|dmg|flac|r70|mdf|chm|sisx|sis|flv|thm|bin|swf|cert|otf|ttf|eot|svgx?|woff2?|jar|class|log|web[ma]|ogv)'
  if [[ -z $__suffix || $__suffix =~ \.1$ ]] ; then
    __data=$(for i in ${__install_list} ; do
               __alen=$(wc -l /var/log/apache2/${i}.access.log${__suffix} 2>/dev/null|awk '{print $1}')
               __nlen=$(wc -l /var/log/nginx/${i}.access.log${__suffix} 2>/dev/null|awk '{print $1}')
               __statics=$(egrep -c ${static_regex} /var/log/nginx/${i}.access.log${__suffix} 2>/dev/null)
               echo -e "$i ${__alen:-0} ${__statics} ${__nlen:-0}"
             done)
  elif [[ $__suffix =~ \.[2-9]\.gz ]] ; then
    __data=$(for i in ${__install_list} ; do
               __alen=$(zcat /var/log/apache2/${i}.access.log${__suffix} 2>/dev/null | wc -l | awk '{print $1}')
               __nlen=$(zcat /var/log/nginx/${i}.access.log${__suffix} 2>/dev/null| wc -l | awk '{print $1}')
               __statics=$(zcat /var/log/nginx/${i}.access.log${__suffix} | egrep -c ${static_regex} 2>/dev/null)
               echo -e "$i ${__alen:-0} ${__statics} ${__nlen:-0}"
             done)
  fi
  echo "${__data}" | awk '{atot=atot+$2 ; ntot=ntot+$4-$3 } ; END {print "\033[1mTOTAL CACHED: " ntot-atot "/" ntot " ( "100-100*atot/ntot"% )\033[0m" }'
  echo | awk '{printf "\033[1m%-30s %-6s %-6s %-6s %-s\033[0m\n","install","apache","static","nginx","cache_pct"}'
  echo "${__data}" | awk '$3 != 0 {printf "%-30s %-6s %-6s %-6s %-6.2f\n",$1,$2,$3,$4,100-100*$2/($4-$3)}' | grep -v "\-nan" | sort -k2 -rn
  unset __alen __nlen __data __suffix __install_list static_regex
}
