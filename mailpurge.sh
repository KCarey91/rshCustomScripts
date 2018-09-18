#!/bin/bash
#
# CKmail
#
### Variables ###
sites_dir='/nas/wp/www/sites'
staging_dir='/nas/wp/www/staging'
# this is already done in redshell.  ftw.
#_sites()
#{
#    local cur=${COMP_WORDS[COMP_CWORD]}
#    local sites=$(ls /nas/wp/www/sites)
#    COMPREPLY=( $(compgen -W "$sites" -- $cur) )
#}
# add to auto-complete
complete -F _sites ckdisk dush clearautoptimize
# note: colors like ${teal} are defined in redshell too
###---------------###
### my tmp folder ###
###---------------###
# Make a tmp folder, don't call it 'root' if in sudo screen.
# Shouldn't need to be root anyway, but just in case.
if [[ $SUDO_USER ]]; then
  db_tmp_dir="/var/tmp/$SUDO_USER"
else
  db_tmp_dir="/var/tmp/$USER"
fi
function db_tmp(){
  if [[ -e $db_tmp_dir ]]; then
    # clean up previous whatever
    rm -rf $db_tmp_dir
  fi
  # (re)create folder
  mkdir $db_tmp_dir
}
function cleanup(){
  # clean up our stuff
  sudo rm -rf $db_tmp_dir
  # for wpinfo - remove me later
  rm /home/dbennett_/rsh_custom/wpinfo.php
  rm /home/dbennett_/rsh_custom/colors.php
}
###------###
### Mail ###
###------###
#
# https://wpengine.atlassian.net/wiki/display/SYS/Outbound+SPAM
#
# Check mail queue for stuff goin on
function ckmail(){
  # Vars
  mail_file=$db_tmp_dir/mailq.txt
  sha_file=$db_tmp_dir/mailshas.txt
  if [[ -e $mail_file ]]; then
    while getopts 'r' opt; do
      if [[ $opt = 'r' ]]; then
        new_mail_file='true'
      fi
    done
  fi
  if [[ $new_mail_file || ! -e $mail_file ]]; then
    echo -e "\nClearing tmp and refreshing mail files...\n"
    # Make sure the tmp folder exists and is fresh.
    db_tmp
    # Write detailed mail queue to a file
    mailq | grep '^[0-9,A-F]' | tr -d '*' | awk '{print $1}' | while read id; do
      echo -ne "$id\t"
      sudo postcat -q $id
    done > $mail_file
    # Write site shas to their own file
    ls -1 $sites_dir/ | while read i; do
      echo -n "$i  "
      echo -n $i | sha1sum | cut -d' ' -f1
    done > $sha_file
### Check for blocked accounts
#    cat $sha_file | awk '{ print $2 }' | while read sha:q
  fi
  if [[ ! -e $mail_file || ! -e $sha_file ]]; then
    echo -e "\n${red}Uh ohs, I'm missing my files for some reason:${NC}\n$mail_file\n$sha_file\n"
    return
  else
    # Output info about items in the queue
    echo -e "\n${teal}Up to 20 Most Recent Emails:${NC}\n"
    egrep --color=always '^(Subject|To: |X-WPE-Internal-ID)|^.*ENVELOPE' $mail_file | tail -80
    # Output stuff - using ``` zendesk markdown for easy copy/paste
    # Get most common sender IDs
    # might be a better way to do this...
    echo -e "\n${teal}Most common mailer ID(s):${NC}\n"
    echo '```'
    egrep '^X-WPE-Internal-ID' $mail_file | cut -d' ' -f2 | while read line; do
      grep $line $sha_file
    done | sort | uniq -c | sort -rn | head | column -t
    echo '```'
    # @todo
    # check for null hash: d910b02871075d3156ec8675dfc95b7d5d640aa6
    # Get most common subjects
    echo -e "\n${teal}Most common Subjects:${NC}\n"
    echo '```'
    egrep '^Subject: ' $mail_file | cut -d' ' -f2-  | sort | uniq -c | sort -rn | head
    echo '```'
    # Get most common recipients
    echo -e "\n${teal}Most common recipients:${NC}\n"
    echo '```'
    egrep '^To: ' $mail_file | awk '{ print $NF }'  | sort | uniq -c | sort -rn | head
    echo '```'
    # Number of unique recipients
    echo -e "\n${teal}Number of unique recipients:${NC}\n"
    printf '    '
    egrep '^To: ' $mail_file | sort | uniq | wc -l
  fi
  # just a newline
  echo
  unset new_mail_file 2> /dev/null
  # check for bad POST requests
  echo -e "\n${teal}Possibly bad POST requests:${NC}\n"
  grep -H POST /var/log/apache2/*.access.log | cut -d/ -f5- | awk '{ if ($9 ~ /200/) print $1, $7}'\
    | awk -F '[: ]' '{print $1, $NF}' | cut -d? -f1 | sed -e 's#\.access.log# #g' -e 's# /# #g'\
    | grep -vE 'admin-ajax.php$|wp-cron.php$|wp-login.php$|xmlrpc.php$|wp-comments-post.php$|bvautodump.php$|/trackback/$|wp-admin/post.php$|wp-admin/async-upload.php$|wp-admin/admin-post.php$|wp-admin/nav-menus.php$|wp-admin/admin.php$'\
    | grep 'php$' | sort | uniq -c | sort -rn | head | column -t
  # clean up our tmp dir
#  cleanup
}
# Disable email for an account.
function disablemail(){
  # Requires install name be provided, and $mail_file comes from `ckmail` above
  if [[ -z $1 || -z $mail_file ]]; then
    echo "This needs an install name, and \`ckmail\` should be run first.."
    return
  else
    mail_hash=$(grep $1 $sha_file | awk '{ print $2 }')
    echo -e "${red}$1${NC} $mail_hash"
    sudo touch /var/spool/proxsmtp/disable.${mail_hash}
  fi
}
# Clear mail queue
function clearmailq(){
  if [[ -z $1 || ! $1 =~ [a-z0-9]{35,45} ]]; then
    echo -e "\nYo dawg, I need a mail hash as the first argument.\n"
    return
  else
    mail_hash="${1}"
    printf "\nAre you sure you want to clear the mail queue? (y/n) "
    read confirm_clear
    if [[ $confirm_clear == "y" ]]; then
      mailq | grep '^[0-9,A-F]' | tr -d '*' | awk '{print $1}' | while read id; do
        sudo postcat -q $id | grep $mail_hash && postsuper -d $id
      done
    else
      echo -e "\nOkie dokes, not clearing mail queue then.\n"
    fi
  fi
}
