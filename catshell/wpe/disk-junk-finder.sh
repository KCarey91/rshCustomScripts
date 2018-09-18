#!/bin/bash
## Checks for stuff that might be causing disk usage problems and can usually be deleted.
##    Usage: disk-junk-finder   (no arguments)
##  More will be added as I find other common problems.  Currently checks:
##   __wpe_admin_ajax_log debug.log _wpeprivate/(backups,etc)

function disk-junk-finder() {
   echo -e "${BRIGHT}${MAGENTA}==== Large _wpeprivate folders ===${NORMAL}"
   du -sm /nas/content/{live,staging}/*/_wpeprivate 2>/dev/null | grep '^[0-9][0-9]\+' | cut -f2|  xargs -r du -sh | sort -rh

   echo -e "${BRIGHT}${MAGENTA}==== Large _wpeprivate files older than 7 days ===${NORMAL}"
   du -sm /nas/content/{live,staging}/*/_wpeprivate 2> /dev/null | grep '^[0-9][0-9]\+' |
     while read dir ; do
       find /${dir#*/} -maxdepth 1 -mindepth 1 -name '*backup*' -o -iname '*.sql' -o -iname '*content*' -not -name 'config.json' -o -name '*.zip' -o -iname '*.gz' -mtime +7 -print0
     done | xargs -0 -r du -sh | grep -v "^4.0K"| sort -rh

   echo -e "${BRIGHT}${MAGENTA}==== Log Files ===${NORMAL}"
   find /nas/content/ -maxdepth 3 -mindepth 3 -name wp-content -print0 2>/dev/null |
     xargs -0 -r -n 1 | xargs -r -P10 -I@ find @ -maxdepth 1 -mindepth 1 -name '*debug.log*' -o -name '*__wpe_admin_ajax.log*' -print0 2>/dev/null |
       xargs -0 -r du -sh fgsfds 2>/dev/null | grep -v "^4.0K"  | sort -rh

   echo -e "${BRIGHT}${MAGENTA}=== Old Staging Uploads Directories ===${NORMAL}"
   if [[ -n /etc/wpengine/disabled/staging_redirect_404_to_prod ]] ; then
     old_upload_dirs=$(find /nas/content/staging/ -maxdepth 6 -mindepth 4 -regex '.*/20\(0[0-9]\|1[1-6]\)$' -print0  | xargs -0 --no-run-if-empty du -sh | sort -rh)
     for user in $(echo "${old_upload_dirs}" | cut -d/ -f5 | sort | uniq) ; do
       if [[ -n $(grep 'WP_ALLOW_MULTISITE.*true' /nas/content/staging/${user}/wp-config.php) ]] ; then
         old_upload_dirs=$(echo "${old_upload_dirs}" | grep -v "/${user}/")
       fi
     done
     echo "${old_upload_dirs}" | egrep '[0-9.]+[GM]' --color=never
   else
     echo -e "\033[1;31mStaging-to-Live Redirect Disabled.  Skipping.\033[0m"
   fi

   echo -e "${BRIGHT}${MAGENTA}==== Large Cache Dirs ===${NORMAL}"
   { find /nas/content/live -mindepth 3 -maxdepth 7 -name 'cache' -print0 ; find /nas/content/staging/ -mindepth 3 -maxdepth 5 -name 'cache' -print0 ; } | xargs -0 -r du -sh | sort -rn | \grep '^[0-9.]*G'

   echo -e "${BRIGHT}${MAGENTA}==== Large Backup Plugin Dirs ===${NORMAL}"
   find /nas/content/ -mindepth 2 -maxdepth 6 -type d -regex '/nas/content/\(staging\|live\)/[a-z0-9]*/wp-content/\(ai1wm-backups\|uploads/ithemes-security/backups\)' -print0 | xargs -0 -r du -sh | sort -rh | \grep '^[0-9]*[GM]'

   echo -e "${BRIGHT}${MAGENTA}=== Proxied Installs Still on Server===${NORMAL}"
   grep 'Forwarding server configuration' /nas/config/nginx/* |
     while read conf ; do
       conf=${conf%%.conf:*} ; conf=${conf##*/}
       echo -e "(${conf}:$(php /opt/nas/www/tools/wpe.php option-get ${conf} cluster))\t$(paste <(du -sh /nas/content/live/${conf}/ 2>/dev/null) <(du -sh /nas/content/staging/${conf}/ 2>/dev/null))"
     done  | grep -v "${conf}:$(cat /etc/cluster-id)" |grep '/nas/content/'|column -t| sort -k2 -rh

   echo -e "${BRIGHT}${MAGENTA}=== LargeFS-Enabled Sites' Upload Dirs ===${NORMAL}"
   largefs_installs=$(grep amazonaws /nas/config/nginx/*.conf | awk -F'\\.|/' '{print $5}' | sort | uniq 2>/dev/null)
   for i in ${largefs_installs} ; do
     largefs_upload_path=$(php /opt/nas/www/tools/wpe.php option-get-json ${i} largefs | jq -r '.[].path')
     du -sh /nas/content/live/${i}${largefs_upload_path} 2>/dev/null
   done | sort -rh

   echo -e "${BRIGHT}${MAGENTA}=== Misc Locations: ===${NORMAL}"
   {
      du -sh /var/cache/eaccelerator /tmp
   } 2>/dev/null | sort -rh

#   echo -e "${BRIGHT}${MAGENTA}===Staging Sites w/ no recent access logs===${NORMAL}"
#     for i in $(ls /nas/content/staging/) ; do
#       [[ -z $(ls /var/log/apache2/staging-${i}.access.log* 2>/dev/null) ]] && echo "$i"
#     done  | while read install ; do du -sh /nas/content/staging/${install} 2>/dev/null ; done | grep -v "^4.0K" | sort -rh

}
