#! /bin/bash

## Grep through all php files in current/sub directories without grepping other things like images, etc.
##  A bit of a misnomer; also will grep through CSS/JS files.
##
##   phpfind search_term
##
## Tack on -c or -j to the end to include css or javascript files.

function phpfind() {
   findregex='\(php'
   [[ ${*:2} =~ -c?j ]] && findregex+='\|js'
   [[ ${*:2} =~ -j?c ]] && findregex+='\|css'
   findregex+='\)'
   find . -type f -regex ".*\.${findregex}$" -print0 | LC_ALL=C xargs -0 -P25 fgrep --color -nH "${1}"
}
