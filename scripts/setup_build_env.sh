#!/bin/bash

if [[ -z "${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN}" ]] || [[ -z "${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN}" ]]; then
  echo "Environment Variables 'ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN' or 'ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN' are not set"
  return 1
fi

export ANSIBLE_GALAXY_SERVER_LIST=automation_hub_certified,automation_hub_validated,upstream_galaxy
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_URL=https://console.redhat.com/api/automation-hub/content/published/
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_AUTH_URL=https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_URL=https://console.redhat.com/api/automation-hub/content/validated/
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_AUTH_URL=https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
export ANSIBLE_GALAXY_SERVER_UPSTREAM_GALAXY_URL=https://galaxy.ansible.com

echo "Build Environment Variables Have Been Configured"

