#! /bin/bash
## Checks wp-config.php to see what CDNs are configured for the account and
##  prints off their CDN URLs.   Run by itself from user's home directory.
function cdn_info() {
  user=$(pwd|cut -d/ -f5)
  grep 'wpe_netdna_domains=' /nas/content/live/${user}/wp-config.php | tr ')' '\n'|grep zone|
  while read line ; do
    domain=${line#*match\' => \'} domain=${domain%%\'*}
    zone=${line#*zone\' => \'} ; zone=${zone%%\'*}
    echo -e "${CYAN}###= ${BRIGHT}${domain} ${NORMAL}${CYAN}=###${NORMAL}"
    echo -e "HTTP: http://${zone}.wpengine.netdna-cdn.com/"
    echo -e "SSL: https://${zone}-wpengine.netdna-ssl.com/"
  done
}
