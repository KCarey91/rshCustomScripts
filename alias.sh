#!/bin/bash
alias s='title="${USER}$(date +%s)";sudo screen -S "$title" -d -m -c /dev/null;sudo screen -S $title -X stuff "source ~${USER}/.bash_profile $(printf \\\\n)";sudo screen -x $title'
