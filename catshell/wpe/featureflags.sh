#! /bin/bash
## Prints off a list of common feature flags and colors them based on whether or not they're present or not.
##   Useful for quickly checking what flags are enabled and remembering which ones go where.
##     Usgage:  featureflags
function featureflags() {
  feature_flags_wiki="https://wpengine.atlassian.net/wiki/display/SYS/Feature+Flags"
  feature_flags=("/etc/wpengine/enabled/dont_kill_cron" "/etc/wpengine/disabled/kill-long-apache-processes" "/etc/wpengine/enabled/staging-ssl" "/var/run/cease-auto-blocking-ips" "/etc/wpengine/disabled/staging_redirect_404_to_prod /etc/wpengine/disabled/wpex-bucket-max-active-slots")

  echo -e "${BRIGHT}Key: ${GREEN}Present ${RED}Not-Present${NORMAL} ( ${feature_flags_wiki} )"
  for flag in ${feature_flags[@]} ; do
    if [[ -f $flag ]] ; then
      echo -e "${BRIGHT}${GREEN}${flag}${NORMAL} $(stat -c %z ${flag})"
    else
      echo -e "${BRIGHT}${RED}${flag}${NORMAL}"
    fi
  done | column -t
}
