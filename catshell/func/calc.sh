#! /bin/bash
##  Opening new windows is dumb and so is typing out commands to do math.
##  No calculator, less typing.  Just make that darn computer do your math.
##     calc "20*2"   or just 'calc' to go to calculator mode. (ctrl+c exit)

function calc() {
  if [[ ! -z $1 ]]
   then python -c "print (1.0 * $*)"
  else
    while read -p "> " ; do python -c "print ('A:',$REPLY)" ; done
  fi
}
