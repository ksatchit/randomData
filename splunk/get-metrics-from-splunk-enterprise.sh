#!/bin/bash

# Set your Splunk Cloud token and base URL
SPLUNK_TOKEN="<Your_Token_Here>"
SPLUNK_URL="https://testgroup.splunkcloud.com:8089"
SEARCH_QUERY='search index=_metrics metric_name="cpu.usage" | stats avg(cpu.usage) by host'
OUTPUT_MODE="json"

# Step 1: Submit the search request to create the search job
echo "Submitting search job..."
response=$(curl -s -k -H "Authorization: Bearer $SPLUNK_TOKEN" \
  -d "search=$SEARCH_QUERY" \
  -d "output_mode=$OUTPUT_MODE" \
  "$SPLUNK_URL/services/search/jobs")

# Check if the response contains an error
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to submit search job."
  exit 1
fi

# Extract the search job ID (SID) from the response
sid=$(echo "$response" | xmllint --xpath "string(//sid)" -)
if [[ -z "$sid" ]]; then
  echo "Error: Failed to obtain search job ID."
  exit 1
fi

echo "Search job ID: $sid"

# Step 2: Poll the search job until it's done
echo "Polling search job to check status..."

while true; do
  job_status=$(curl -s -k -H "Authorization: Bearer $SPLUNK_TOKEN" \
    "$SPLUNK_URL/services/search/jobs/$sid")

  # Check for any errors in the response
  if [[ $? -ne 0 ]]; then
    echo "Error: Failed to check job status."
    exit 1
  fi

  dispatch_state=$(echo "$job_status" | xmllint --xpath "string(//dispatchState)" -)
  status=$(echo "$job_status" | xmllint --xpath "string(//status)" -)

  if [[ "$dispatch_state" == "DONE" ]]; then
    echo "Search job completed."
    break
  elif [[ "$status" == "failed" ]]; then
    echo "Error: Search job failed."
    exit 1
  fi

  echo "Waiting for search job to complete..."
  sleep 5
done

# Step 3: Retrieve the results once the search job is complete
echo "Retrieving search results..."

results=$(curl -s -k -H "Authorization: Bearer $SPLUNK_TOKEN" \
  "$SPLUNK_URL/services/search/jobs/$sid/results?output_mode=$OUTPUT_MODE")

# Check for any errors in the response
if [[ $? -ne 0 ]]; then
  echo "Error: Failed to retrieve search results."
  exit 1
fi

# Step 4: Parse and display the host-wise average CPU usage
echo "Parsing and displaying results..."

# Use jq to parse the JSON results (make sure jq is installed)
echo "$results" | jq -r '.results[] | "Host: \(.host), Average CPU Usage: \(.avg_cpu_usage)"'

# Final message
echo "Script completed successfully."
