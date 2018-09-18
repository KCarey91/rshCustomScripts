#! /bin/bash
## podinfo : wpephp server-option-get CID
##  Usage:  podinfo (CID)
##    CID Defaults to current Pod.

function podinfo() {
  [[ -n $1 ]] && _podnum=${1} || _podnum=$(cat /etc/cluster-id)
  php /opt/nas/www/tools/wpe.php server-option-get ${_podnum}
}
