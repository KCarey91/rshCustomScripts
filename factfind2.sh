 #!/bin/bash
# Description: Fact finder
function fact_find2(){
        for i in $(php /nas/wp/www/tools/wpe.php get-sites-clean $(cat /etc/cluster-id) 1 1)
        do    
            if [ -f /var/log/nginx/${i}.access.log ]
            then
                	varnish_hits=$(egrep "127.0.0.1:9002" /var/log/nginx/${i}.access.log | wc -l)
                	apache_hits=$(egrep "127.0.0.1:6789" /var/log/nginx/${i}.access.log | wc -l)
                	total_hits=$(cat /var/log/nginx/${i}.access.log | wc -l)
                	echo "Traffic for -" $i
                	echo "Varnish hits:" $varnish_hits
                	echo "Apache hits:" $apache_hits
                	echo "Total hits:" $total_hits
                	echo "Cache percent of total hits:" $(($varnish_hits*100/$total_hits)) %
                	echo
        	else 
        			echo "No Logs for this install" $i
				echo
        	fi
        done
}
