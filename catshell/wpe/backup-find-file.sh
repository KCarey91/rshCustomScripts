#! /bin/bash

## Search previous snappyshot backups for a specific file.
##  Arguments:
##    -d <number>       Days back to search
##    -u <user>         User to check
##    -f <file>         File to check: e.g.:  wp-content/mysql.sql
##    -s                Check Staging instead of live

function backup-find-file() {
  user='@@@placeholder@@@' file=''
  unset OPTIND
  while getopts "d:u:f:s" opt ; do
    case ${opt} in
     f) file=${OPTARG} ;;
     u) user=${OPTARG} ;;
     d) days=${OPTARG} ;;
     s) staging="1" ;;
     \?) if [[ -z $help ]] ; then echo "Search previous snappyshot backups for a specific file.
   Arguments:
     -d <number>       Days back to search
     -u <user>         User to check
     -f <file>         File to check: e.g.:  wp-content/mysql.sql
     -s                Check Staging instead of live"
        fi ; help=1 ;;
    esac
  done ; shift $((OPTIND-1))
  [[ -n $staging ]] && site='staging' || site='live'
  [[ -z ${days} ]] && days=5
  if [[ -d /nas/wp/www/sites/${user} && -n ${file} ]] ; then
    snappyshot snapshot:list ${user}-${site} | tail -n${days} |
      while read line ; do
        echo -e "${line% * * * *}\t\t\c"
        snap_result=$(snappyshot snapshot:findfile ${user}-${site} ${line%% *} ${file})
        if [[ $snap_result =~ "File/Directory not found" ]] ; then
          echo -e "\033[1;31m${snap_result}\033[0m"
        elif [[ $snap_result =~ "File found:" ]]; then
          echo -e "\033[1;32m${snap_result}\033[0m"
        else echo ${snap_result}
        fi
      done
  fi; unset snap_result days site file user
}
