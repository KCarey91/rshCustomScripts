mysreport ()
{
	sudo echo
	echo "============Podinfo============="
	podinfo
	echo "================================"
	echo;echo
	echo "============pt-summary============="
        sudo pt-summary
        echo "================================"
        echo;echo
	echo "============pt-mysql-summary============="
        sudo pt-mysql-summary
        echo "================================"
        echo;echo
	echo "============pt-mysql-slow-log============="
        sudo pt-query-digest /var/log/mysql/mysql-slow.log | head -250
        echo "================================"
	echo;echo
	echo "============DB Size============="
	sudo find /nas/mysql/ -maxdepth 1 -type d -exec bash -c "sudo du -hs '{}'" \; | sort -rhk1 | head
	echo "================================"
	echo;echo
	echo "============Number of tables=============="
	sudo find /nas/mysql/ -maxdepth 1 -type d -exec bash -c "echo -ne '{} '; sudo ls '{}' | egrep ibd | wc -l" \; | sort -nrk2 | head
	echo "================================"
	echo;echo
	echo "============Number of myisam tables============"
	sudo find /var/lib/mysql/ -type f -name '*.MYI' | cut -d/ -f5 | sort | uniq -c | sort -rn | head
	echo "================================"
	echo;echo
}
