#!/bin/bash
## Print off some information about Connect Time (TTFB), Transfer Time, Total Time for downloading a page.
## Useful for determining TTFB/Page download/generation problems vs page rendering problems.
## Low scores with this means a slow page is likely from scripts/other crap loading on the page.
##
## Usage:  loadtime domain.com/optional/path.here [additional curl arguments]
##     eg: loadtime eremite.moe -A "Mozilla Firefox" --user user:pass
## Output meaning:  https://curl.haxx.se/docs/manpage.html  (see --write-out section)

function loadtime {
  [[ $1 =~ \? ]] && uri="$1&cache_bust_$(date +%s)" || uri="$1?cache_bust_$(date +%s)"
  _curl_format='
            time_namelookup:  %{time_namelookup}
               time_connect:  %{time_connect}
            time_appconnect:  %{time_appconnect}
           time_pretransfer:  %{time_pretransfer}
              time_redirect:  %{time_redirect}
         time_starttransfer:  %{time_starttransfer}
                     ------- -----------
                 time_total:  %{time_total}

             speed_download:  %{speed_download}_bytes/s
              size_download:  %{size_download}_bytes
               num_connects:  %{num_connects}
              num_redirects:  %{num_redirects}
'
 printf "%20s\033[4m%s\033[0m%40s\033[4m%s\033[0m" " " "First Pass" " " "Repeat View"
 result_1="$(curl ${*/$1/} --insecure -L -o /dev/null -s -w "$_curl_format" ${uri} | while read l ;  do printf "%25s %-25s\n" $l ; done)"
 result_2="$(curl ${*/$1/} --insecure -L -o /dev/null -s -w "$_curl_format" ${uri} | while read l ;  do printf "%25s %-25s\n" $l ; done)"
 paste -d ' ' <(echo "$result_1") <(echo "$result_2")
 echo -e "\n\033[4mRedirect Chain:\033[0m\nOriginal: ${uri}"
 curl --insecure -sIL ${uri} | grep "Location:"
 unset _curl_format
}
