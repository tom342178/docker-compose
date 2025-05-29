#!/bin/bash

# Parameters
CONN="127.0.0.1:32149"            # REST connection (IP:Port)
DBMS="new_company"                # Logical DB name
TABLE="my_table"                  # Table name

# Function to generate 10 JSON rows with timestamp and value
generate_data() {
  for i in {1..10}
  do
    TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    VALUE=$((RANDOM % 100))
    echo "{\"timestamp\":\"$TIMESTAMP\",\"value\":$VALUE}"
    sleep 1
  done
}

# Send each row using curl
generate_data | while read -r row
do
  curl -X PUT "http://${CONN}" \
    -H "type: json" \
    -H "dbms: ${DBMS}" \
    -H "table: ${TABLE}" \
    -H "mode: streaming" \
    -H "Content-Type: text/plain" \
    -H "User-Agent: AnyLog/1.23" \
    --data "$row"

  echo ""  # Just for spacing
done