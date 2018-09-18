function extract () {

unset -v compfile1 compfile2 compfile3 compfile4 compfile5 compfile6 compfile7 compfile8 compfile9 compfile10 compfile11 compfile12

compfile1="(\.tar.bz2)"
compfile2="(\.tar.gz)"
compfile3="(\.bz2)"
compfile4="(\.rar)"
compfile5="(\.gz)"
compfile6="(\.tar)"
compfile7="(\.tbz2)"
compfile8="(\.tgz)"
compfile9="(\.zip)"
compfile10="(\.Z)"
compfile11="(\.7z)"

  if [[ $1 =~ $compfile1 ]] ; then
    tar xvjf $1
  elif [[ $1 =~ $compfile2 ]] ; then
    tar xvzf $1
  elif [[ $1 =~ $compfile3 ]] ; then
    bunzip2 $1
  elif [[ $1 =~ $compfile4 ]] ; then
    unrar x $1
  elif [[ $1 =~ $compfile5 ]] ; then
    gunzip $1
  elif [[ $1 =~ $compfile6 ]] ; then
    tar xvf $1
  elif [[ $1 =~ $compfile7 ]] ; then
    tar xvjf $1
  elif [[ $1 =~ $compfile8 ]] ; then
    tar xvzf $1
  elif [[ $1 =~ $compfile9 ]] ; then
    unzip $1
  elif [[ $1 =~ $compfile10 ]] ; then
    uncompress $1
  elif [[ $1 =~ $compfile11 ]] ; then
    7z x $1
  elif [ "$1" = "" ] ; then
    echo -e "\nFilename:"; read -e compfile12;
    echo -e ""
    if [[ $compfile12 =~ $compfile1 ]] ; then
      tar xvjf $compfile12
    elif [[ $compfile12 =~ $compfile2 ]] ; then
      tar xvzf $compfile12
    elif [[ $compfile12 =~ $compfile3 ]] ; then
      bunzip2 $compfile12
    elif [[ $compfile12 =~ $compfile4 ]] ; then
      unrar x $compfile12
    elif [[ $compfile12 =~ $compfile5 ]] ; then
      gunzip $compfile12
    elif [[ $compfile12 =~ $compfile6 ]] ; then
      tar xvf $compfile12
    elif [[ $compfile12 =~ $compfile7 ]] ; then
      tar xvjf $compfile12
    elif [[ $compfile12 =~ $compfile8 ]] ; then
      tar xvzf $compfile12
    elif [[ $compfile12 =~ $compfile9 ]] ; then
      unzip $compfile12
    elif [[ $compfile12 =~ $compfile10 ]] ; then
      uncompress $compfile12
    elif [[ $compfile12 =~ $compfile11 ]] ; then
      7z x $compfile12
    else
      echo -e "Enter filename (.tar.bz2, .tar.gz, .bz2, .rar, .gz, .tar, .tbz2, .tgz, .zip, .Z, .7z)\n"
    fi
  else
    echo -e "Enter filename (.tar.bz2, .tar.gz, .bz2, .rar, .gz, .tar, .tbz2, .tgz, .zip, .Z, .7z)\n"
  fi

}
