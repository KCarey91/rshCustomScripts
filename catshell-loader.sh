#!/bin/bash
# Sets working directory to the 'catshell' folder in the script's directory.
SOURCE=$(cd $(dirname ${BASH_SOURCE[0]});pwd)/catshell
# Check to see if we're on a server or workstation
[[ -f /etc/cluster-id ]] && ispod="sho nuff"

# Terminal color variables (workstation & server)
source ${SOURCE}/color_cat

# Load up aliases
source ${SOURCE}/alias_cat
if [[ -n $ispod ]] ; then
  source ${SOURCE}/alias_cat_pod
  source ${SOURCE}/pod-motd.catshell
fi

# Set Alias for Help File
# Remove old .sh and .bash files because of redshell's sourcing strategy now.
[[ -f ${SOURCE}/meow.sh ]] && rm -v ${SOURCE}/meow.sh
[[ -f ${SOURCE}/meow.bash ]] && rm -v ${SOURCE}/meow.bash
alias meow="bash ${SOURCE}/meow.catshell"

# Load core functions
for file in $(find ${SOURCE}/func -type f) ; do
  source ${file}
done

#Generate aliases for items in the scripts directory.
# Have to remove the old .bash and .sh files since redshell derps them up. :/
find ${SOURCE}/scripts -type f -iname "*.sh" -print -delete
find ${SOURCE}/scripts -type f -iname "*.bash" -print -delete

for i in $(find ${SOURCE}/scripts -type f) ; do
  script=${i##*/}
  case ${script##*.} in
    catshell) alias ${script%%.*}="bash ${SOURCE}/scripts/${script}" ;;
    py) alias ${script%%.*}="python ${SOURCE}/scripts/${script}" ;;
  esac
done

# Load some fun functions with no real application.
for file in $(find ${SOURCE}/fun -type f) ; do
  source ${file}
done

# Load WPE-specific functions
for file in $(find ${SOURCE}/wpe/ -type f) ; do
  source ${file}
done

# Updates END
echo -e "${BLACK}${BOLD} /\_/\ ${NORMAL}    HAYO! CatShell     | 'meow' or 'purr' for help"
echo -e "${BLACK}${BOLD}( ${GREEN}^${NORMAL}${MAGENTA}ᴥ${BOLD}${GREEN}^${BLACK} )${NORMAL}  merging to \033[1;31mredshell\033[0m. |      *Final Version*"

unset SOURCE ispod
