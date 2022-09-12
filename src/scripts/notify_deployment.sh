run () {
  verify_env_variables
  generate_json_payload_deployment
  post_to_compass
}

verify_env_variables () {
  if [[ ! ${COMPASS_SHARED_SECRET} || ! ${COMPASS_WEBTRIGGER} ]]; then
    echo "The environment variables required for the Compass orb aren’t configured. Please check if you’ve configured the integration correctly in the Compass UI."
    exit 0
  fi
}

generate_json_payload_deployment () {
  iso_time=$(date '+%Y-%m-%dT%T%z'| sed -e 's/\([0-9][0-9]\)$/:\1/g')
  echo {} | jq \
  --arg time_str "$(date +%s)" \
  --arg lastUpdated "${iso_time}" \
  --arg category "${ENVIRONMENT_TYPE^^}" \
  --arg environmentType "${ENVIRONMENT_TYPE}" \
  --arg workflowId "${CIRCLE_WORKFLOW_ID}" \
  --arg jobId "${CIRCLE_BUILD_NUM}" \
  --arg status "${COMPASS_BUILD_STATUS}" \
  '
  ($time_str | tonumber) as $time_num |
  {
    "workflowId": $workflowId,
    "jobId": $jobId,
    "lastUpdated": $lastUpdated,
    "status": $status,
    "deployments": [
      {
          "environment": {
            "category": $category,
            "displayName": $environmentType,
            "environmentId": $environmentType
          },
        "lastUpdated": $lastUpdated
      }
    ]
  }
  ' > /tmp/compass-status.json
}


post_to_compass () {
  cat /tmp/compass-status.json
  eval TOKEN=\$$TOKEN_NAME #most portable way to use dynamic variable name
  HTTP_STATUS=$(curl \
  -u "${TOKEN}:" \
  -s -w "%{http_code}" -o /tmp/curl_response.txt \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -H "x-forge-secret: ${COMPASS_SHARED_SECRET}" \
  -X POST "${COMPASS_WEBTRIGGER}" --data @/tmp/compass-status.json)

  echo "Results from Compass: "
  if [ "${HTTP_STATUS}" != "200" ];then
    echo "Error calling Compass, result: ${HTTP_STATUS}" >&2
    jq '.' /tmp/curl_response.txt
    exit 0
  fi

  # If reached this point, the deployment was a success.
  echo
  jq '.' /tmp/curl_response.txt
  echo
  echo
  echo "Success!"
}

# kick off
source ${STATE_PATH}
run
rm -f ${STATE_PATH}