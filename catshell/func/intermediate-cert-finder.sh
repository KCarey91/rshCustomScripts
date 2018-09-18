#! /bin/bash
##  Finds and downloads the intermediate-cert-finder for a provided certificate
##  If there's a chain, it shoudl follow that to the end.
##   Usage:
##       intermediate-cert-finder customer-certificate.crt

function intermediate-cert-finder() {
  if [[ -f $1 ]]; then
    cert=$(cat $1) todays_date=$(date +%Y-%m-%d) intermediate_content=''
    while [[ $(echo "${cert}" | openssl x509 -text -noout | grep "CA Issuers") ]] ; do
      intermediate_cert=$(echo "$cert" | openssl x509 -text -noout | grep "CA Issuers")
      intermediate_cert=${intermediate_cert#*:}
      response="$(curl -s $intermediate_cert | openssl x509 -inform der -outform pem)
"
      intermediate_content="${intermediate_content}${response}"
      cert=${response}
    done
    echo "$intermediate_content" > ${todays_date}.${intermediate_cert##*/}
    echo -e "\033[1;32mIntermediate Cert Saved to: \033[0;32m ${todays_date}.${intermediate_cert##*/}\n\033[1;32mCombined Cert for copy/pasta:\033[0m\n"
    cat ${1} ${todays_date}.${intermediate_cert##*/}
  else echo -e "\033[1;31mPlease provide a cert file:  \033[0;31mintermediate-cert-finder <CRT_File>\033[0m"
  fi; unset intermediate_content response cert todays_date intermediate_cert
}
