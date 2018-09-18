#! /bin/bash
## Script for finding and cleaning up disk space on a server automatically
disk-clean ()
{
	unset report verbose
	[[ $* =~ -v ]] && verbose=1
	# Get free megabytes.
	GREEN=$(tput setaf 2)
	RED=$(tput setaf 1)
	BOLD=$(tput bold)
	NORMAL=$(tput sgr0)
	statusmsg() {
	  echo -e " =(^ᴥ^)= ${BOLD}${GREEN}$*${NORMAL}"
	}
	freem() {
	  df -m /nas | awk '! /Filesystem/ {print $4}'
	}
	# Remove staging uploads from 2016 or earlier if the corresponding file
	#  also exists in live for all installs.
	statusmsg "Cleaning Staging Uploads older than 2016 if dupe exists on live."
	report=${report}"Staging Uploads,$(freem),"
	find /nas/content/staging/ -mindepth 4 -maxdepth 6 -regex '.*/20\(0[0-9]\|1[0-6]\)$' |
	  while read sdir ; do
	    find "${sdir}" -type f |
	      while read file ; do
		if [[ "${file}" =~ /staging/ && -f "${file/staging/live}" ]] ; then
		  [[ ${verbose} == 1 ]] && rm -v "${file}" || rm "${file}"
		fi
	      done
	   done
	report=${report}"$(freem)\n"
	# Clear all autoptimize caches.
	report=${report}"Autoptimize Cache,$(freem),"
	statusmsg "Cleaning autoptimize caches for all installs."
	for install in $(find /nas/content -maxdepth 5 -mindepth 5 -type d -regex '/nas/content/\(live\|staging\).*/cache/autoptimize$') ; do
	   cd ${install%%wp-content*}
	   skip_plugins=$(wp --skip-themes --skip-plugins plugin list --status=active --field=name 2>/dev/null| grep -v "^autoptimize$"| tr '\n' ',')
	   if sudo -u www-data wp --skip-plugins=${skip_plugins} --skip-themes eval '$clearme = new autoptimizeCache("whatevs"); $clearme->clearall();' ; then
	     true
	   else
	     cd ${install} && find ${install} -type f -name 'autoptimize_*' -delete
	   fi
	done
	report=${report}"$(freem)\n"
	# Clear AIO Event Calendar Caches.
	report=${report}"AI1-Event-Calendar Cache,$(freem),"
	statusmsg "Cleaning All-In-One-Event-Calendar caches for all installs."
	cd ~ ; find /nas/content/live -maxdepth 5 -mindepth 5 -regex '.*/all-in-one-event-calendar/cache$' | while read cache ; do find ${cache} -type f -delete ; done
	report=${report}"$(freem)\n"
	# Remove all admin-ajax logs and debug.log files and disable future logging.
	report=${report}"Debug/Ajax Logs,$(freem),"
	statusmsg "Clearing out admin ajax and debug logs."
	find /nas/content/ -maxdepth 4 -mindepth 4 -regex '^/nas/content/\(live\|staging\)/[^/]*/wp-content/\(debug.log\|__wpe_admin_ajax.log\)$' -delete -print
	report=${report}"$(freem)\n"
	# Git GC all the /nas/git-cache/ .git directories
	report=${report}"git-cache,$(freem),"
	statusmsg "Running git cleanup on /nas/git-cache/ .git dirs"
	for dir in $(find /nas/git-cache/ -maxdepth 3 -type d -name '.git') ; do
	  cd ${dir}
	  git config pack.threads 1
	  git config pack.deltaCacheSize 512m
	  git config pack.packSizeLimit 512m
	  git config pack.windowMemory 512m
	  ionice -c2 -n6 nice -n19 git gc --prune=now
	done
	report=${report}"$(freem)\n"
	# Build a report of freed space:
	echo "${GREEN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NORMAL}"
	echo -e ${report} | awk -F, 'BEGIN {printf "%s,%s,%s,%s\n","Check","Before","After","Freed"}; ! /^$/ {totalfree+=$2-$3; printf "%s,%s,%s,%s\n",$1,$2,$3,$2-$3}; END {printf "%s%s\n","Total Freed: ", totalfree}' | column -s, -t
	echo "${GREEN}~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~${NORMAL}"
}
