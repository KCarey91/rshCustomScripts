ckmail is a function
ckmail2 ()
{
    mail_file=$db_tmp_dir/mailq.txt;
    sha_file=$db_tmp_dir/mailshas.txt;
    if [[ -e $mail_file ]]; then
        while getopts 'r' opt; do
            if [[ $opt = 'r' ]]; then
                new_mail_file='true';
            fi;
        done;
    fi;
    if [[ -n $new_mail_file || ! -e $mail_file ]]; then
        echo -e "\nClearing tmp and refreshing mail files...\n";
        db_tmp;
        mailq | grep --color=auto '^[0-9,A-F]' | tr -d '*' | awk '{print $1}' | while read id; do
            echo -ne "$id\t";
            sudo postcat -q $id;
        done > $mail_file;
        ls --color=auto -1 $sites_dir/ | while read i; do
            echo -n "$i  ";
            echo -n $i | sha1sum | cut -d' ' -f1;
        done > $sha_file;
    fi;
    if [[ ! -e $mail_file || ! -e $sha_file ]]; then
        echo -e "\n${red}Uh ohs, I'm missing my files for some reason:${NC}\n$mail_file\n$sha_file\n";
        return;
    else
        echo -e "\n${teal}Up to 20 Most Recent Emails:${NC}\n";
        egrep --color=auto --color=always '^(Subject|To: |X-WPE-Internal-ID)|^.*ENVELOPE' $mail_file | tail -80;
        echo -e "\n${teal}Most common mailer ID(s):${NC}\n";

        echo '```';
        egrep --color=auto '^X-WPE-Internal-ID' $mail_file | cut -d' ' -f2 | while read line; do
            grep --color=auto $line $sha_file;
        done | sort | uniq -c | sort -rn | head | column -t;
        echo '```';

        echo -e "\n${teal}Most common Subjects:${NC}\n";
        echo '```';
        egrep --color=auto '^Subject: ' $mail_file | cut -d' ' -f2- | sort | uniq -c | sort -rn | head;
        echo '```';
        echo -e "\n${teal}Most common recipients:${NC}\n";
        echo '```';
        egrep --color=auto '^To: ' $mail_file | awk '{ print $NF }' | sort | uniq -c | sort -rn | head;
        echo '```';
        echo -e "\n${teal}Number of unique recipients:${NC}\n";
        printf '    ';
        egrep --color=auto '^To: ' $mail_file | sort | uniq | wc -l;

        echo -e "\n${teal}Top 10 post requests per hour today ${NC}\n";
        Current_hour=$(date +'%H')
        #Back_hour=$(expr ${Current_hour} - 1)
        #Current_year=$(date +"%Y")
        badmailer=$(egrep --color=auto '^X-WPE-Internal-ID' $mail_file | cut -d' ' -f2 | while read line; do grep --color=auto $line $sha_file; done | sort | uniq | sort -rn | head -1 | awk '{print$1}';)

        echo '```';
        #grep '$Current_year:[$Current_hour-$Back_hour]' /var/log/nginx/$badmailer.access.log | grep POST | awk '{print$3}'
        for i in $(eval echo {00..$Current_hour});do echo -e ${red} $(date +'%d-%m-%y' -d 'today') $i;egrep $(date +20'%y:')$i /var/log/nginx/$badmailer.access.log | grep 'POST' | awk '{print "\033[32m" $3}' | sort | uniq -c | sort -rn | head -3; done
        echo '```';

        echo -e "\n${teal}Top 10 POST requests today from $badmailer ${NC}\n";
        echo '```';
        grep POST /var/log/nginx/$badmailer.access.log | awk '{print$3}' | sort | uniq -c | sort -rn | head
        echo '```';
    fi;
    echo;
    unset new_mail_file 2> /dev/null;
}

