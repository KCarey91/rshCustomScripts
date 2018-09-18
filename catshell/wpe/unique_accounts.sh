#!/bin/bash
# Counts up total number of unique accounts utilizing the pod in question
#  (This is based on bucket name (wpe_customer_account_name variable)
#  so it may show more unique accounts than truly exist. Check userinfo to be sure.

#function unique_accounts() {
#  unset installs pcres accounts
#  installs=$(ls /nas/content/live | tr '\n' ' ')
#  while [[ $installs =~ [a-z] ]] ; do
#     pcres=$(cluster parent-child ${installs%% *})
#     accounts="$accounts ${pcres%% *}"
#     for i in ${pcres} ; do
#       installs=${installs/$i /}
#     done
#  done
#  echo "Unique Accounts ($(echo ${accounts} | wc -w)) : ${accounts}"
#}

function unique_accounts() {
  accounts=$(grep -hoP '(?<=wpe_customer_account_name ")[^"]*' /nas/config/nginx/*.conf | sort -u | tr '\n' ' ')
  echo "Unique Accounts: ($(echo $accounts | wc -w)) : $accounts"
}
