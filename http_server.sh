#!/bin/bash

PORT=8787
QUEUE_SERVER=localhost
QUEUE_PORT=8788
REPLICA=2

trap 'pkill -P $$ &> /dev/null' INT
trap 'pkill -P $$ &> /dev/null' EXIT

function connection_handler() {

	FIFO_FILE=proc.$1.reply.fifo
	mkfifo $FIFO_FILE &> /dev/null

	USERID="iamuser"
	COUNT=0
	while IFS=$'\r\n' read line; do

		if [ ${#line} == 0 ]; then
			COUNT=0

			# command : reply cahnnel : user id
			echo "ORDER:$1:$USERID" > /dev/tcp/$QUEUE_SERVER/$QUEUE_PORT

			# Waiting for result from reply channel
			IFS=: read ID STATUS < $FIFO_FILE

			if [ "$STATUS" == "SUCCESS" ]; then
				echo -en "HTTP/1.1 200 OK\r\n"
				echo -en "Content-Length: ${#STATUS}\r\n"
				echo -en "\r\n"
				echo -en $STATUS
				echo -en "\r\n"
			else
				echo -en "HTTP/1.1 400 Bad Request\r\n"
				echo -en "Content-Length: ${#STATUS}\r\n"
				echo -en "\r\n"
				echo -en $STATUS
				echo -en "\r\n"
			fi

			continue
		fi

		COUNT=$[COUNT+1]

		# Check token
		if [ "${line%: *}" == "Authentication" ]; then
			TOKEN=${line#*: }

			# TODO: Authentication mechanism

			# PASS ALWAYS
			USERID="blah"
			continue
		fi

		echo ">>> ${line}" >&2

	done < "${2:-/dev/stdin}"
}

function createProcess() {

	FIFO_FILE=proc.$1.fifo
	mkfifo $FIFO_FILE &> /dev/null

	nc -l -k $PORT < $FIFO_FILE | connection_handler "$1" > $FIFO_FILE &
}

# Start mulitiple processes to handle connections
echo "Replica is $REPLICA"
for i in $(seq 1 $REPLICA); do
	echo "Starting process $i ..."
	createProcess $i
done

echo "Listening on port $PORT"

wait
