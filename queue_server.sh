#!/bin/bash

PORT=8788
REPLICA=2

trap 'pkill -P $$ &> /dev/null' INT
trap 'pkill -P $$ &> /dev/null' EXIT

# Start mulitiple processes to handle connections
echo "Replica is $REPLICA"
for i in $(seq 1 $REPLICA); do
	nc -l -k $PORT >> mask.db &
done

echo "Listening on port $PORT"

wait
