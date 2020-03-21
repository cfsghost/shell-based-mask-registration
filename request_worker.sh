#!/bin/bash

tail -n 0 -f mask.db | \
while read line; do

	echo $line
	IFS=: read COMMAND REPLY_CHANNEL USERID <<< "$line"

	# TODO: implement a database to handle transaction

	echo "$USERID:SUCCESS" > proc.$REPLY_CHANNEL.reply.fifo
done
