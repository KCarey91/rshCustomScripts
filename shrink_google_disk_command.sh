#!/bin/bash
# Generate copy pasta for shrinking google disks.
#  Usage:  shrink_google_disk_command_gen.sh CID OFFERING
#     eg:   shrink_google_disk_command_gen.sh 199999 p1

CID=$1
OFFERING=$2
SIZE_OVERRIDE=$3
DISKSUFFIX=$4

NOW=$(date +%Y%m%d)
case $OFFERING in
  p0) DISKSIZE=100 ; DISKTYPE=pd-ssd ;;
  p1) DISKSIZE=100 ; DISKTYPE=pd-ssd ;;
  p2) DISKSIZE=200 ; DISKTYPE=pd-ssd ;;
  p3) DISKSIZE=300 ; DISKTYPE=pd-ssd ;;
  p4) DISKSIZE=400 ; DISKTYPE=pd-ssd ;;
  p5) DISKSIZE=500 ; DISKTYPE=pd-ssd ;;
  p6) DISKSIZE=1000 ; DISKTYPE=pd-ssd ;;
esac
ZONE=$(ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=quiet -o ConnectTimeout=5 pod-${CID}.wpengine.com "php /opt/nas/www/tools/wpe.php server-option-get ${CID} | grep -oP '(?<=availability_zone\] => ).*'")

[[ -n ${SIZE_OVERRIDE} ]] && DISKSIZE=${SIZE_OVERRIDE}

# Shouldn't need to touch the stuff below.
echo -e "\033[1;33m/dev/sdb and pod-XXXXX-nas are ASSUMED and may need to be edited manually if they are different.\033[0m"

echo -e "\033[1;31mOn CM \033[0;31m"
echo gcloud compute disks list --filter="name~'.*${CID}-nas.*'"
echo gcloud compute disks snapshot --snapshot-names=pod-${CID}-nas-${NOW} --zone ${ZONE} pod-${CID}-nas${DISKSUFFIX}
echo gcloud compute snapshots list --filter="name~'.*${CID}.*'"
echo gcloud compute disks create --description="'modify pod to ${OFFERING}'" --type=${DISKTYPE} --zone=$ZONE "pod-$CID-nas-$(date +%Y%m%d)" --size=${DISKSIZE}GB
echo  gcloud compute instances attach-disk pod-${CID} --disk=pod-${CID}-nas-${NOW} --zone=${ZONE}

echo -e "\033[1;32mOn POD \033[0;32m"
echo  "for i in zabbix-agent nginx varnish varnishncsa docker apache2 mysql td-agent ; do service \$i stop ; done && lsof | grep /nas && umount /nas && echo -e '\033[1;32m/nas UNMOUNTED. Good to go.\033[0m' || echo -e '\033[1;31m/nas NOT UNMOUNTED. Review Output.\033[0m'"
echo
echo  lvresize --size $(( ${DISKSIZE} -1 ))G -r /dev/vg_pod$CID/lv_pod$CID '&&' mount /nas "&& for i in mysql apache2 docker varnish nginx varnishncsa td-agent zabbix-agent ; do service \$i start ; done"
echo
echo "pvcreate /dev/sdc && vgextend vg_pod$CID /dev/sdc && pvmove -v /dev/sdb /dev/sdc && vgreduce vg_pod$CID /dev/sdb && pvremove /dev/sdb && lvresize -l+100%FREE -r /dev/vg_pod$CID/lv_pod$CID && sudo php /opt/nas/www/tools/wpe.php server-option-set ${CID} pod disk ${DISKSIZE} && rm -v /nas/local/server-meta/*"

echo -e "\033[1;31mOn CM Again: \033[0;31m"
echo  gcloud compute instances detach-disk pod-$CID --disk=pod-${CID}-nas${DISKSUFFIX} --zone=$ZONE
echo  gcloud compute disks delete pod-${CID}-nas${DISKSUFFIX} --zone=$ZONE
