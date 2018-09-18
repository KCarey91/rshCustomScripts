#! /bin/bash
## Find all unique accounts, then total up all installs under that account
##  to see their total and individual disk usage.
##        Usage: top_disk_user | tee ~/disk_usage_totals.txt
## Sort results to see top user:
##   grep -oP '(?<=Account: ).*(?=total)' ~/disk_usage_totals.txt | sort -k3rn

function top_disk_user() {
  unique_accts=$(grep -hoP '(?<=wpe_customer_account_name ")[^"]*' /nas/config/nginx/*.conf | sort -u | tr '\n' ' ')
  for account in ${unique_accts};do
    echo -ne "\n======( Account: $account :: "
    { echo /nas/content/live/$account /nas/content/staging/$account
      for child in $(grep -l "wpe_customer_account_name.*${account}" /nas/config/nginx/* | xargs grep -l 'http://localhost:6788');do
      install=${child%.*} ; install=${install##*/} ; echo /nas/content/live/${install} /nas/content/staging/${install}
    done ; } | sort | uniq | xargs du -smc  2>/dev/null | grep -v '^1\s' | sort -rn
  done
}
