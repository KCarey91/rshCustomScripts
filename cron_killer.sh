#!/bin/bash
function cron_killer(){
	echo "Before you murdered a bunch of sleeping innocents"
	pstree $(ps faux|grep [c]ron|awk '{print $2}'|head -1) -p -a -l
	pstree $(ps faux|grep [c]ron|awk '{print $2}'|head -1) -p -a -l | cut -d, -f2 | cut -d' ' -f1 | tr '\n' ' ' | cut -d' ' -f1 --complement | xargs -n1 sudo kill -9
	echo "Nothing left now but parents and tears.... so many tears :'("
	pstree $(ps faux|grep [c]ron|awk '{print $2}'|head -1) -p -a -l
}
