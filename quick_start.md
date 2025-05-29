# Quick Start

## Requirements
* Make 
* Docker & Docker Compose 

## Port Configurations
| Node Type | TCP | REST | 
| :---: | :---: | :---: | 
| Master | 32048 | 32049 | 
| Operator 1 | 32148 | 32149 | 
| Operator 2 | 32158 | 32159 |

## Deployment

**Clone EdgeLake's docker-compose**

```shell
cd $HOME/
git clone https://github.com/EdgeLake/docker-compose
cd docker-compose/
```

**Master**: The master node will also act as our query node
1. Start Master Node 
```shell
make up EDGELAKE_TYPE=master
```

2. Using `docker logs`, get the local TCP IP and port. This will be used for Master 

```anylog
macbookpro:docker-compose orishadmon$ docker logs -f edgelake-master

EdgeLake Version: 1.3.2504 [0f2c17] [2025-04-20 17:12:25] (Release)

* (c) 2021-2023 AnyLog Inc.
*
* This software is licensed under the terms and conditions of the AnyLog SOFTWARE EVALUATION AGREEMENT
* available at https://github.com/AnyLog-co/documentation/blob/master/License/Evaluation%20License.md 

EL edgelake-master > 
    Process         Status       Details                                                                   
    ---------------|------------|-------------------------------------------------------------------------|
    TCP            |Running     |Listening on: 24.5.219.50:32048 and 172.20.0.2:32048, Threads Pool: 6    | <-- 
    REST           |Running     |Listening on: 24.5.219.50:32049, Threads Pool: 5, Timeout: 20, SSL: False|
    Operator       |Not declared|                                                                         |
    Blockchain Sync|Running     |Sync every 30 seconds with master using: 127.0.0.1:32048                 |
    Scheduler      |Running     |Schedulers IDs in use: [0 (system)] [1 (user)]                           |
    Blobs Archiver |Not declared|                                                                         |
    MQTT           |Not declared|                                                                         |
    Message Broker |Not declared|No active connection                                                     |
    SMTP           |Not declared|                                                                         |
    Streamer       |Not declared|                                                                         |
    Query Pool     |Running     |Threads Pool: 3                                                          |
    Kafka Consumer |Not declared|                                                                         |
    gRPC           |Not declared|                                                                         |
    OPC-UA Client  |Not declared|                                                                         |
```
**Operator 1**:
1. In [docker-makefiles/edgelake_operator.env](docker-makefiles/edgelake_operator.env), update the IP address of the 
LEDGER_CONN to the TCP IP:Port for Master node 
```shell
# before
LEDGER_CONN=127.0.0.1:32048

# after
LEDGER_CONN=172.20.0.2:32048
```

You can also configure other options in the .env file, including setting the logical database name and enabling the MQTT client to simulate random data generation.

2. Start Operator Node 
```shell
make up EDGELAKE_TYPE=operator
```

**Operator 2**:
1. In [docker-makefiles/edgelake_operator2.env](docker-makefiles/edgelake_operator2.env), update the IP address of the 
LEDGER_CONN to the TCP IP:Port for Master node 
```shell
# before
LEDGER_CONN=127.0.0.1:32048

# after
LEDGER_CONN=172.20.0.2:32048
```

You can also configure other options in the .env file, including setting the logical database name and enabling the MQTT client to simulate random data generation.

2. Start Operator Node 
```shell
make up EDGELAKE_TYPE=operator2
```


## Insert + Query Data 
* Simple Insert Data of 10 rows into EdgeLake
```shell
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
```

* Query Data 
```shell
CONN="127.0.0.1:32049"            # REST connection (IP:Port) for Query node 
DBMS="new_company"                # Logical DB name
TABLE="my_table"                  # Table name

curl -X GET http://${CONN} \
  -H "sql ${DBMS} format=table SELECT * FROM ${TABLE}" \
  -H "User-Agent: AnyLog/1.23" \
  -H "destination: network"
```
