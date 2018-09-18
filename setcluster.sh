setcluster ()
{
    if [ -z "$1" ]; then
        echo "syntax: ";
        echo "setcluster INSTALL NEW OLD";
    else
        sudo php /nas/wp/www/tools/wpe.php option-set "$1" cluster "$2";
        sudo php /nas/wp/www/tools/wpe.php option-set "$1" cluster-previous "[$3]";
        echo "If the output is 1 for each, it should be all set! Let's see if it worked...";
        echo "Here's the new cluster: ";
        wpephp option-get-json "$1" cluster;
        printf "\n";
        echo "Here's the old cluster: ";
        wpephp option-get-json "$1" cluster-previous;
        printf "\n";
    fi
}
