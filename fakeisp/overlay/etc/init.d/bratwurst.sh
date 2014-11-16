#!/bin/sh -e
### BEGIN INIT INFO
# Provides:          bratwurst.sh
# Required-Start:    urandom
# Required-Stop:     
# Default-Start:     S
# Default-Stop:
# Short-Description: Startup prep for BRatWuRsT
### END INIT INFO

PATH=/sbin:/usr/sbin:/bin:/usr/bin

. /lib/lsb/init-functions

set -e

case "$1" in
	start|restart|force-reload|reload)
		log_action_begin_msg "Setting up BRatWuRsT "
		STATUS=0
		/opt/bratwurst/init || STATUS=$?
		log_action_end_msg $STATUS
		;;
	stop)
		;;
	status)
		;;
	*)
		echo "Usage: /etc/init.d/bratwurst.sh {start|stop|restart|reload|force-reload|status}" >&2
		exit 3
		;;
esac

exit 0
