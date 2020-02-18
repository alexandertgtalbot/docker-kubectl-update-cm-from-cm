#!/usr/bin/env bash

set -e          # Exit immediately if any subsequent command fails. 
set -o nounset  # Fail fast if required environment variables are not set or empty.
set -o pipefail # Prevent pipelined errors from being masked.

# This should prove to be redundant in the context of single-run 
# containers, i.e. k8s jobs, but here for completeness.
function cleanup {
  rm -f /tmp/*.yaml
}
trap cleanup EXIT

# Convert REMOVE_CONFIG to lowercase and test if set to 'true' or 'false'.
if [ "${REMOVE_CONFIG,,}" == "false" ]
then
  # Add or update a data element (key-value pair), i.e. config in the master Config Map.
  kubectl patch cm -n "${TARGET_CONFIG_MAP_NAMESPACE}" "${TARGET_CONFIG_MAP_NAME}" --patch "{ \"data\": $(kubectl get cm -n ${REFERENCE_CONFIG_MAP_NAMESPACE} ${REFERENCE_CONFIG_MAP_NAME} -o json | jq '.data') }"

elif [ "${REMOVE_CONFIG,,}" == "true" ]
then
  # Get full JSON config for the Config Map.
  kubectl get cm -n "${TARGET_CONFIG_MAP_NAMESPACE}" "${TARGET_CONFIG_MAP_NAME}" -o json > "/tmp/${TARGET_CONFIG_MAP_NAME}.yaml"

  # Remove a config (data element) from the Config Map.
  cat "/tmp/${TARGET_CONFIG_MAP_NAME}.yaml" | jq ". | del(.data.\"${CUSTOM_CONFIG_NAME}\")" > "/tmp/${TARGET_CONFIG_MAP_NAME}_new.yaml"

  # Update the Config Map.
  kubectl replace -f "/tmp/${TARGET_CONFIG_MAP_NAME}_new.yaml"

else
  echo "Environment variable REMOVE_CONFIG should be set to either 'true' or 'false'."
  return 1
fi