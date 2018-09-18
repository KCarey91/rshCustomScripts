#! /bin/bash
## Check DNS for domains added to a list of installs.  Compares IP from cname with IP the domain resolves to.
##  Also will check to see if the site passes the CDN check in case it's pointed, but going through a CDN.
##    Usage:  dns_checker list of installs

function dns_checker() {
  echo -e "Legend:"
  echo -e "  PASS PASS = Pointed correctly passes CDN check"
  echo -e "  FAIL PASS = Not pointed correctly, but is loading from us (via CDN,etc)"
  echo -e "  FAIL FAIL = Not pointed and fails CDN check ; likely loading from other host."
  echo -e ""
  echo -e "Pointing Method: "
  echo -e "        actualip_A = Pointed via A Record"
  echo -e "        actualip_C = Pointed via WPE CNAME"
  echo -e "        actualip_O = Pointed via other CNAME"

  installs=${*}
  for install in ${installs} ; do
    cname=$(dig +short ${install}.wpengine.com | tail -n1)
    echo -e "\n=== Install: ${install} ==="
    domains=$(grep all_domains /nas/content/live/${install}/wp-config.php | grep -oP "(?<==> ')[^']*" | grep -v 'wpengine.com')
    printf "%-40s %-20s %-20s %-20s %-20s\n" "Domain" "ExpectedIP" "ActualIP" "Match/CDN-Check" "OrgName"
    for domain in ${domains} ; do
      dns=$(dig +short ${domain}|tail -n1)
      dighead=$(dig +short ${domain} | head -n 1)
      [[ ${dighead} =~ ^[0-9.]*$ ]] && method="A"
      [[ ${dighead} =~ ^${install}.wpengine.com.$ ]] && method="C"
      [[ -z ${method} ]] && method="O"
      orgname=$(whois ${dns} 2>/dev/null| awk '/^OrgName:/ {$1="" ; print}'|head -n1)
      [[ ${dns} == ${cname} ]] && result="${BRIGHT}${GREEN}PASS${NORMAL}" || result="${BRIGHT}${RED}FAIL${NORMAL}"
      cdncheck=$(curl -s --insecure -L -o /dev/null -w "%{http_code}"  http://${domain}/-wpe-cdncheck-)
      [[ ${cdncheck} == "200" ]] && cdncheck="${BRIGHT}${GREEN}PASS${NORMAL}" || cdncheck="${BRIGHT}${RED}FAIL${NORMAL}"
      printf "%-40s %-20s %-20s %-50s %-20s\n" "${domain}" "${cname}" "${dns}_${method}" "${result} ${cdncheck}" "${orgname#* }"
    done
  done
}
