#! /bin/bash
## countdown SECONDS
## Prints off a countdown visually instead of using a sleep with no output.
##  Probably not as accurate, but ¯\(ツ)/¯

countdown() {
  [[ $1 =~ ^[0-9]+$ ]] || return 1
  derpspin=('-' '\' '|' '/')
  for i in $(seq 1 $1); do
    echo -ne " (${1}s)    ${derpspin[$((${i} % 4))]}   $(($1 - $i))              \r"
    sleep 1
  done
}
