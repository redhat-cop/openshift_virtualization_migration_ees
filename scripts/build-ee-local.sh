#!/bin/bash

set -euo pipefail

AAP_VERSION=${1:-"2.7"}

echo "🚀 Configuring environment variables.."
if [[ -z "${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN}" ]] || [[ -z "${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN}" ]]; then
  echo "Environment variables 'ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN' or 'ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN' are not set.  See README.md for instructions."
  exit 1
fi
if [[ -z "${REDHAT_ORG}" ]] || [[ -z "${REDHAT_ACTIVATION_KEY}" ]]; then
  echo "Environment variables 'REDHAT_ORG' or 'REDHAT_ACTIVATION_KEY' are not set. See README.md for instructions."
  exit 1
fi
export ANSIBLE_GALAXY_SERVER_LIST=automation_hub_certified,automation_hub_validated,upstream_galaxy
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_URL=https://console.redhat.com/api/automation-hub/content/published/
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_AUTH_URL=https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_URL=https://console.redhat.com/api/automation-hub/content/validated/
export ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_AUTH_URL=https://sso.redhat.com/auth/realms/redhat-external/protocol/openid-connect/token
export ANSIBLE_GALAXY_SERVER_UPSTREAM_GALAXY_URL=https://galaxy.ansible.com
echo "✅ Environment variables have been configured."

echo "🚀 Creating build context..."
ansible-builder create -f openshift-virtualization-migration-ee-${AAP_VERSION}/execution-environment.yml --output-filename=Containerfile --verbosity 3
echo "✅ Build context has been created."

echo "🚀 Building image..."
podman build \
  --build-arg "REDHAT_ORG=${REDHAT_ORG}" \
  --build-arg "REDHAT_ACTIVATION_KEY=${REDHAT_ACTIVATION_KEY}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_URL=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_URL}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_AUTH_URL=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_AUTH_URL}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_CERTIFIED_TOKEN}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_URL=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_URL}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_AUTH_URL=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_AUTH_URL}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN=${ANSIBLE_GALAXY_SERVER_AUTOMATION_HUB_VALIDATED_TOKEN}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_UPSTREAM_GALAXY_URL=${ANSIBLE_GALAXY_SERVER_UPSTREAM_GALAXY_URL}" \
  --build-arg "ANSIBLE_GALAXY_SERVER_LIST=${ANSIBLE_GALAXY_SERVER_LIST}" \
  -f context/Containerfile \
  -t "openshift-virtualization-migration-ee:${AAP_VERSION}"
echo "✅ Image has been built."

echo "🚀 Scanning image for vulnerabilities..."
if trivy image --config trivy.yaml "openshift-virtualization-migration-ee:${AAP_VERSION}"; then
  echo "✅ Image has been scanned. No CRITICAL vulnerabilities found."
else
  echo "❌ CRITICAL vulnerabilities found!" >&2
  exit 1
fi

echo "✅ Execution Environment created successfully!"
