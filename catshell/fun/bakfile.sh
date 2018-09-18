#! /bin/bash
## A few quick functions for backing up files in a way that they're still usable.
##   eg: file.jpg becomes file.bak.jpg instead of file.jpg.bak
##     ( .bak will be prepended before the final .ext extension. )
##  Also, ubakfile will remove any .bak listed in the filename. :D
# Not that useful, but a fun exercise in variable substitution. 

function bakfile() {
  for i in $*
    do mv -vi $i ${test%.*}.bak.${test##*.}
  done
}

function ubakfile() {
  for i in $*
   do mv -vi $i ${test%.bak.*}.${test##*.bak.}
  done
}
