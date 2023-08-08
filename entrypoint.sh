#!/bin/bash

set -e

port_client_id="$INPUT_PORTCLIENTID"
port_client_secret="$INPUT_PORTCLIENTSECRET"
port_run_id="$INPUT_PORTRUNID"
pagerduty_token="$INPUT_TOKEN"
blueprint_identifier="$INPUT_BLUEPRINTIDENTIFIER"
incident_title="$INPUT_INCIDENTTITLE"
extra_details="$INPUT_EXTRADETAILS"
service="$INPUT_SERVICE"
urgency="$INPUT_URGENCY"
actor_email="$INPUT_ACTOREMAIL"

get_access_token() {
  curl -s --location --request POST 'https://api.getport.io/v1/auth/access_token' --header 'Content-Type: application/json' --data-raw "{
    \"clientId\": \"$port_client_id\",
    \"clientSecret\": \"$port_client_secret\"
  }" | jq -r '.accessToken'
}

send_log() {
  message=$1
  curl --location "https://api.getport.io/v1/actions/runs/$port_run_id/logs" \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    --data "{
      \"message\": \"$message\"
    }"
}

add_link() {
  url=$1
  curl --request PATCH --location "https://api.getport.io/v1/actions/runs/$port_run_id" \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    --data "{
      \"link\": \"$url\"
    }"
}

trigger_incident() {
  incident=$(curl  --request POST \
        --url https://api.pagerduty.com/incidents \
        --header 'Accept: application/vnd.pagerduty+json;version=2' \
        --header "Authorization: Token token=$pagerduty_token" \
        --header 'Content-Type: application/json' \
        --header "From: $actor_email" \
        --data "{
            \"incident\": {
              \"type\": \"incident\",
              \"title\": \"$incident_title\",
              \"service\": {
                \"id\": \"$service\",
                \"type\": \"service_reference\"
              },
              \"urgency\": \"$urgency\",
              \"body\": {
                \"type\": \"incident_body\",
                \"details\": \"$extra_details\"
              }
            }
      }")

  echo $incident
  incident_id=$(echo $incident | jq -r '.incident.id')
  incident_html_url=$(echo $incident | jq -r '.incident.html_url')

  add_link "$incident_html_url"
  send_log "Incident created with id $incident_id at $incident_html_url"

  send_log "Reporting to Port the new entity created 🚢"
  report_to_port "$incident_id" "$incident_title"
}


report_to_port() {
  identifier=$1
  title=$2
  curl --location "https://api.getport.io/v1/blueprints/$blueprint_identifier/entities?run_id=$port_run_id" \
    --header "Authorization: Bearer $access_token" \
    --header "Content-Type: application/json" \
    --data "{
      \"identifier\": \"$identifier\",
      \"title\": \"$title\",
      \"properties\": {}
    }"
}

main() {
  access_token=$(get_access_token)

  send_log "Triggering a new incident at pager duty $repository_name 🚨"
  trigger_incident
  send_log "Finished triggering incident! 🏁✅"
}

main