#! /bin/bash

##  Rememberizing flags is hard, man.  Sometimes you're all like, I'm just gonna
##    extract this simple archive.  Should be easy.
##   BUT WAIT, what flags do you need?  What's the command? What the heck is .Z?
##  Got you covered, my man.  Just hit "extract filename" and it'll take a loook
##       at what you got and be like, "Yo man, I know how to extract this."
##   Unless it doesn't know, then you just gotta suck it up, y'know?

extract () {
  if [ -f $1 ] ; then
      case $1 in
          *.tar.bz2)   tar xvjf $1    ;;
          *.tar.gz)    tar xvzf $1    ;;
          *.bz2)       bunzip2 $1     ;;
          *.rar)       rar x $1       ;;
          *.gz)        gunzip $1      ;;
          *.tar)       tar xvf $1     ;;
          *.tbz2)      tar xvjf $1    ;;
          *.tgz)       tar xvzf $1    ;;
          *.zip)       unzip $1       ;;
          *.Z)         uncompress $1  ;;
          *.7z)        7z x $1        ;;
          *)           echo "don't know how to extract '$1'..." ;;
      esac
  else
      echo "'$1' is not a valid file!"
  fi
}
