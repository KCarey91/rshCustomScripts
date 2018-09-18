mailpurge ()
{
    for install in $*;
    do
        mail-tool enable ${install};
        mail-tool disable ${install} --permanent;
    done;
    for install in $*;
    do
        mail-tool q d ${install} --confirm;
    done
} 
