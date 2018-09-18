#! /bin/bash

## Provides help with catshell
##
##   meow                   ::  List help categories/Topics
##   meow {cat}             ::  Provide information about the category
##   meow {cat} {function}  ::  Provide details about a function
##
## Note: category info is from .help files in each subfolder of ~/.catshell
##       function information is from comments prepended by ##
function meow() {
  if [[ -z $1  ]]
   then echo -e "${bldblu} meow (category) [command]\n${bldpur}Help Topics:${txtrst}"
    for dir in ~/.catshell/{func,scripts,wpe,fun}
      do echo -e "${bldgrn}${dir##*/}${txtrst}"
        for file in $(find $dir -type f -not -name "\.*")
          do echo -e "  ${txtgrn}$(basename ${file%.*})${txtrst}"
        done
     done
  elif [[ ! -z $1 && -z $2 ]]
    then [[ -d ~/.catshell/$1 ]] && cat ~/.catshell/$1/.help || echo -e "${txtred}Argument 1 is not a Category. :<${txtrst}"
  elif [[ ! -z $1 && ! -z $2 ]]
    then match=$(find ~/.catshell/$1 -type f -iname "${2}.*")
    if [[ ! $match == "" ]]
      then for file in ${match}
            do echo; grep "^##" $file | while read line
                                   do echo "${line##\#\#}"
                                  done
            done
     else echo -e "${txtred}Argument 1 must be a category; Argument 2 must be a topic.${txtrst}"
    fi
  fi
}
