#!/bin/bash
echo "Installing connector plugins"
confluent-hub install --no-prompt confluentinc/kafka-connect-elasticsearch:latest
confluent-hub install --no-prompt splunk/kafka-connect-splunk:latest
confluent-hub install --no-prompt confluentinc/kafka-connect-splunk-s2s:latest
#
echo "Launching Kafka Connect worker"
/etc/confluent/docker/run &
#
echo "waiting 2 minutes for things to stabilise"
sleep 120
echo "Starting the s2s conector"

HEADER="Content-Type: application/json"
DATA=$(
  cat <<EOF
{
  "name": "splunk-s2s-source",
  "config": {
    "connector.class": "io.confluent.connect.splunk.s2s.SplunkS2SSourceConnector",
    "topics": "splunk-s2s-events",
    "splunk.s2s.port":"9997",
    "kafka.topic":"splunk-s2s-events",
    "key.converter":"org.apache.kafka.connect.storage.StringConverter",
    "value.converter":"org.apache.kafka.connect.json.JsonConverter",
    "key.converter.schemas.enable":"false",
    "value.converter.schemas.enable":"false",
    "errors.log.enable": false,
    "errors.log.include.messages": false,
    "confluent.topic.bootstrap.servers":"broker:29092",
    "confluent.topic.replication.factor":"1"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors

echo "Starting the Spluk sink connector"

HEADER="Content-Type: application/json"
DATA=$(
  cat <<EOF
{
  "name": "SPLUNKSINK",
  "config": {
    "confluent.topic.bootstrap.servers": "broker:29092",
    "name": "SPLUNKSINK",
    "connector.class": "com.splunk.kafka.connect.SplunkSinkConnector",
    "tasks.max": "1",
    "key.converter": "org.apache.kafka.connect.storage.StringConverter",
    "value.converter": "org.apache.kafka.connect.storage.StringConverter",
    "topics": "CISCO_ASA_FILTERED",
    "splunk.hec.token": "ef16f05f-40e0-4108-a644-5323e02aaa44",
    "splunk.hec.uri": "https://splunk:8090",
    "splunk.hec.ssl.validate.certs": "false",
    "splunk.hec.json.event.formatted": "true"
  }
}
EOF
)

curl -X POST -H "${HEADER}" --data "${DATA}" http://localhost:8083/connectors


echo "Sleeping forever"
sleep infinity
