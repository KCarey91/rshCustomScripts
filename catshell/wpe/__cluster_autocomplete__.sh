## Helper functions and aliases to add auto-complete functionality to cluster commands.
# Notes:
# ${COMP_WORDS[COMP_CWORD]} == Current word being filled.
# ${COMP_WORDS[@]} == Array of all words being auto-completed (including command at [0])

# Declare a cluster alias:
alias cluster='sudo /nas/wp/ec2/cluster'

# Function to be called as the auto-complete for the 'cluster' alias:
function __cluster_autocomplete__() {
  local xpat
  local __cluster_commands="add_new_site_pod add_pod_to_group add-pod-to-group add-proxy-for-site apache apache-analyze-site apache-log-site apache-log-staging-site apply checkpoint-site checkpoint-staging check-ssh-instance check-standby-master-status check-standby-slave-status clean-previous-cluster clean-s3-site clear-server-meta-cache clone-site conf create_4g_pod create_8g_pod curl db-cleanup decompress-file-site delete-cluster delete-cluster-instance delete-instance delete-site delete-staging detail-site detect-active-plugins detect-specs diagnose-site dns-check-site dns-failover dns-node-set down dropbox-push-site dropbox-sync-site echo ensure-dns errors-site errors-staging-site experimental-move external-repository-check external-repository-push find-bad-plugin-site find-rogue-git-files-site fixperms gen-conf get-environment-status get-linode-info get-which-cluster ha-fix-tables ha-gather-db-meta has-enough-space has-myisam ha-table-to-innodb id-site info-instance install-plugin install-theme install-wp kill-long-apache-processes largefs-upload-site linode-dns-update list-checkpoints-site list-instances logs mark-disallowed-plugins migrate-sites-to-preferred-clusters move move-lite move-to-preferred-cluster nginx parent-child perm-reload-apply phase1 phase2 phase3 phase4 prepare prepare-for-shibboleth purge-caches-site purge-varnish push-admin-messages random-db-password random-ftp-password reap-disallowed-plugins recent-changed-files recently-changed record-customer-activity refresh-db regen register-weblog-response-codes register-weblog-summary reinstall-core reload-services reload-services-site reload-services-site-lite remove_new_site_pod restart-services restore-site revert-site revert-staging rexec rollcreds run-nova run-pod-commands send-email-cluster send-email-site set-install-options show-pod-info signup-single-code site-nginx-log-summary smoke-test soapbox-info ssl-drop ssl-generate-csr ssl-retrieve ssl-write stage-site stage-site-exists stream-checkpoint-site suspicious-files-site suspicious-plugins-site sync-hapod-content sync-s3-site sync-standby-master test-instance transfer-instance uncancel-site up update upgrade-wp upgrade-wp-email-4hr upgrade-wp-email-7day upload-checkpoint-site where-site write-file-site xdebug-site"
  local __reload_services_commands="all webs lb mysql nginx config admin utility disk sftp"

  if [[ ${COMP_CWORD} == 1 ]]; then
    xpat=$__cluster_commands  flag="-W"
  elif [[ ${COMP_WORDS[1]} =~ ^move-to-preferred-cluster$ ]] ; then
    if [[ ${COMP_CWORD} == 2 ]]; then
     xpat=$(uname -n) xpat="${xpat#*-}"  flag="-W"
   elif [[ ${COMP_CWORD} == 3 ]]; then
      xpat=$(ls /nas/wp/www/sites/ 2>/dev/null)  flag="-W"
    fi
  elif [[ ${COMP_WORDS[1]} =~ ^(apply|regen|purge-(caches-site|varnish)|largefs-upload-site|fixperms|perm-reload-apply|rollcreds|reinstall-core|uncancel-site|parent-child)$ ]] ; then
    if [[ ${COMP_CWORD} == 2 ]] ; then
      xpat=$(ls /nas/wp/www/sites/ 2>/dev/null)  flag="-W"
    fi
  elif [[ ${COMP_WORDS[1]} =~ ^(reload|restart)-services$ ]] ; then
    if [[ ${COMP_CWORD} == 2 ]] ; then
      xpat=$(uname -n) xpat="${xpat#*-}"  flag="-W"
    elif [[ ${COMP_CWORD} == 3 ]] ; then
      xpat=$__reload_services_commands  flag="-W"
    fi
  elif [[ ${COMP_WORDS[1]} =~ ^clone-site$ ]]; then
    if [[ ${COMP_CWORD} == 2 ]]; then
      xpat=$(uname -n) xpat="${xpat#*-}"  flag="-W"
    elif [[ ${COMP_CWORD} == 3 || ${COMP_CWORD} == 4 ]]; then
      xpat=$(ls /nas/wp/www/sites/ 2>/dev/null)  flag="-W"
    elif [[ ${COMP_CWORD} == 5 || ${COMP_CWORD} == 6 ]]; then
      xpat="production staging" flag="-W"
    fi
  fi

#generate auto-complete reply.
COMPREPLY=( $( compgen ${flag} "${xpat}" -- ${COMP_WORDS[COMP_CWORD]} ))
if [[ -n $cluster_autocomplete_debug ]] ; then
  echo -e "\n\033[0;35mW: ${COMP_WORDS[@]} \nCW:${COMP_CWORD}\n\033[0;36mR: ${COMPREPLY[@]}\033[0m"  >> /tmp/auto-complete.debug
fi
return 0
}

# Affix this function to the cluster alias for auto-complete.
complete -F __cluster_autocomplete__ cluster


# Declare some aliases for common stuff that takes only sitename arguments and a function to handle them.
#  Should detect user based on CWD if not specified.

function __cluster_common_wrapper() {
    [[ -n $2 ]] && _args="${1} ${*/$1/}" || _args="$1 $(pwd|cut -d/ -f5)"
    sudo /nas/wp/ec2/cluster ${_args}
}

function __cluster_common_autocomplete__() {
  local xpat

  if [[ ${COMP_CWORD} == 1 ]]; then
     xpat=$(ls /nas/wp/www/sites/ 2>/dev/null)  flag="-W"
  fi
  #generate auto-complete reply.
  COMPREPLY=( $( compgen ${flag} "${xpat}" -- ${COMP_WORDS[COMP_CWORD]} ))
  if [[ -n $cluster_autocomplete_debug ]] ; then
    echo -e "\n\033[0;35mW: ${COMP_WORDS[@]} \nCW:${COMP_CWORD}\n\033[0;36mR: ${COMPREPLY[@]}\033[0m"  >> /tmp/auto-complete.debug
  fi
  return 0

}

## Aliases & auto-complete assignments:
alias purge='__cluster_common_wrapper purge-varnish'
complete -F __cluster_common_autocomplete__ purge
alias apply='__cluster_common_wrapper apply'
complete -F __cluster_common_autocomplete__ apply
alias regen='__cluster_common_wrapper regen'
complete -F __cluster_common_autocomplete__ regen
alias purge-all='__cluster_common_wrapper purge-caches-site'
complete -F __cluster_common_autocomplete__ purge-all
alias uncancel='__cluster_common_wrapper uncancel-site'
complete -F __cluster_common_autocomplete__ uncancel
alias pra='__cluster_common_wrapper perm-reload-apply'
complete -F __cluster_common_autocomplete__ pra
alias perms='__cluster_common_wrapper fixperms'
complete -F __cluster_common_autocomplete__ perms
