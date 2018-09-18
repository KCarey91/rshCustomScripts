#! /bin/bash
## greps bash history out of /var/log/messages and prints it off with more succinct info:
##  eg:   Sep 9 16:58:41     root            service mysql status
## Also color-codes the user that ran the command based on length of their username.

# Color Demo/Test:
# for i in  1 12 123 1234 12345 123456 1234567 12345678 123456789 1234567890 12345678901 123456789012 1234567890123 12345678901234 123456789012345 1234567890123456 12345678901234567 123456789012345678 1234567890123456789 12345678901234567890 ; do echo "1 2 3 $i " | awk '{ $4="\033[38;05;"length($4)*1011%256"m"$4"\033[0m" ; print $4 }' ; done

function bash_history() {
  zgrep --no-filename ' bash\[[0-9]*\]: [a-z_]*:[^$].*' /var/log/messages{.3.gz,.2.gz,.1,} |
   sed -e 's|\(.*[0-9][0-9]:[0-9][0-9]:[0-9][0-9]\).* bash\[[0-9]*\]:\([^:]*\):#[0-9]*|\1 @ \2 @ |g' |
   awk '{ $5="\033[38;05;"length($5)*1011%256"m"$5"\033[0m" ; print }' |
   column -t -s@
}
