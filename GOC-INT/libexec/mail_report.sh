#!/bin/bash

# Fail if reply-to is not set
if [ -z "$GLIDEIN_MAIL_REPLY_TO" ]; then
    exit 1
fi

tools_path="${GLIDEIN_SRC_DIR}/factory/tools"
source="http://glidein-int.grid.iu.edu/osg_gfactory/"
#source="http://glidein.grid.iu.edu/glidefactory/monitor/glidein_v1_0/"
date=$(eval date +%m-%d-%Y)
factory_name="GOC INT Factory"

mode=$1
shift
target=$1
shift
interval=$1
shift
emails=$1
shift

#echo $emails

case "$mode" in
    ae)
        script=analyze_entries
        if [ "$target" = factory ]; then
            cmd="${tools_path}/${script} --source $source -x $interval -s waste  -l strt,10 --nb;${tools_path}/${script} --source $source -x $interval -s waste -m;${tools_path}/${script} --source $source -x $interval -s waste"
        else
            cmd="${tools_path}/${script} --source $source -x $interval -s waste -f $target"
        fi
    ;;
    aq)
        script=analyze_queues
        if [ "$target" = factory ]; then
            cmd="${tools_path}/${script} --source $source -x $interval -s rundiff -z -m;${tools_path}/${script} --source $source -x $interval -s rundiff -z"
        else
            cmd="${tools_path}/${script} --source $source -x $interval -s rundiff -f $target -z"
        fi
    ;;
    af)
        script=analyze_frontends
        cmd="${tools_path}/${script} --source $source -x $interval -s unmatched -f $target -z"
    ;;
esac

#echo "$cmd"
out=`eval $cmd`
#echo "$out"
retval=$?
#echo $retval

# for now only suppress emailing if error occurs for frontend
if [ $target != "factory" -a $retval -ne 0 ]; then
    exit $retval
fi

if [ "$interval" = 2 ]; then
    subject="${factory_name} ${script} short term report for last ${interval}h on ${date}"
else
    subject="${factory_name} ${script} report for last ${interval}h on ${date}"
fi


/usr/sbin/sendmail -oi -t <<EOF
To: ${emails}
Reply-to: ${GLIDEIN_MAIL_REPLY_TO}
Subject: ${subject}
Content-Type: text/html; charset=us-ascii
Content-Transfer-Encoding: 7bit
MIME-Version: 1.0

<pre>
$out
</pre>

EOF
