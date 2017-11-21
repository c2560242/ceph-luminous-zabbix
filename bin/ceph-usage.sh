#!/bin/bash

# needs second column 'CLASS' for osds to be set;
# otherwise offset for osds must be decreased by 1.

logfile="/tmp/ceph-df.log"
ceph="/usr/bin/ceph"
check="/usr/local/bin/checkrw.sh"

### DO NOT EDIT BELOW ###
_df() {
	df=( `$ceph osd df tree|\
		awk '$10 == "region" {print $5" "$7" "$10"-"$11}; \
		$10 == "host" {print $5" "$7" "$10"-"$11}; \
		$11 ~ /osd/ {print $6" "$8" "$11}'` )
}


_disc() {
	echo -en \{\\n\\t\"data\": \[\\n ;
	for ((i=0;i<${#df[@]};i=$(($i+3)))); do
		if [[ "${df[$(($i+2))]}" =~ region ]]; then
			region=`printf ${df[$(($i+2))]}|sed 's/region-//g'`
			echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#REGION\}\": \"${df[$(($i+2))]}\",\\n;
			echo -en \\t\\t\\t\"\{\#REG_DESCR\}\": \"$region\"\\n\\t\\t\};
		elif [[ "${df[$(($i+2))]}" =~ host ]]; then
			host=`printf ${df[$(($i+2))]}|sed 's/host-//g;s/10.95.11.2/ceph/g;s/ceph0/ceph/g;s/ceph/ceph-/g'`
			echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#HOST\}\": \"${df[$(($i+2))]}\",\\n;
			echo -en \\t\\t\\t\"\{\#HOST_DESCR\}\": \"$host\"\\n\\t\\t\};
		elif [[ "${df[$(($i+2))]}" =~ osd ]]; then
			echo -en \\t\\t\{\\n\\t\\t\\t\"\{\#OSD\}\": \"${df[$(($i+2))]}\",\\n;
			echo -en \\t\\t\\t\"\{\#OSD_DESCR\}\": \"${df[$(($i+2))]} on host $host\"\\n\\t\\t\};
		fi
		if test $i -lt $((${#df[@]}-3)); then
			echo ,
		fi
	done
	echo -en \\n\\t\]\\n\}\\n
}

_percent_usage() {
	awk '/'$1'/ { for (x=1;x<=NF;x++) if ($x == "'$1'") print 100 * $(x-1) }' $logfile
}

_usage() {
	usage=`awk '/'$1'/ { for (x=1;x<=NF;x++) if ($x == "'$1'") print $(x-2) }' $logfile`
	cut=`printf $usage|tr -d TGMK`
	if [[ `echo $usage|egrep G$` =~ "G" ]]; then
		echo $(($cut * 1024 * 1024 * 1024));
	elif [[ `echo $usage|egrep T$` =~ "T" ]]; then
		echo $(($cut * 1024 * 1024 * 1024 * 1024));
	elif [[ `echo $usage|egrep M$` =~ "M" ]]; then
		echo $(($cut * 1024 * 1024))
	elif [[ `echo $usage|egrep K$` =~ "K" ]]; then
		echo $(($cut * 1024));
	fi
}

###
case $1 in
	"discovery") _df; _disc; echo ${df[@]} >$logfile ;;
	"dump") _df; _check_w && echo ${df[@]} >$logfile; _check_r ;;
	"percent") _percent_usage $2 ;; 
	"usage") _usage $2 ;; 
	*)
esac
