## Ever have a big mess of a command output where you can't tell what's error
##   and what's normal output? COLORIZE that junk.
## Stick err_color before a normal command. Error messages turn red. Magic.

err_color()(set -o pipefail;"$@" 2>&1>&3|sed $'s,.*,\e[1;31m&\e[m,'>&2)3>&1

