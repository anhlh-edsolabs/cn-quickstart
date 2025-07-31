#!/bin/bash
# Copyright (c) 2025, Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: 0BSD

# This script is executed by the `splice-onboarding` container. It leverages provided functions from `/app/utils`
# and the resolved environment to onboard a backend service user to a participant (handling user creation and rights assignment),
# and propagating the necessary environment variables to the backend service via the `backend-service.sh` script stored in the shared `onboarding` volume.
# The backend service container sources this shared script during its initialization phase, prior to launching the main process.
# Note: This onboarding script is intended for local development environment only and is not meant for production use.

set -eo pipefail

source /app/utils.sh

# Define users to create (you can easily add/remove users here)
declare -a USER_IDS=(
  "$AUTH_APP_PROVIDER_BACKEND_USER_ID"
  "iou-issuer"
  "iou-owner"
)

declare -a USER_NAMES=(
  "$AUTH_APP_PROVIDER_BACKEND_USER_NAME"
  "iou-issuer"
  "iou-owner"
)

init() {
  local backendUserId=$1
  local userName=$2
  create_user "$APP_PROVIDER_PARTICIPANT_ADMIN_TOKEN" $backendUserId $userName "" "canton:3${PARTICIPANT_JSON_API_PORT_SUFFIX}"
  grant_rights "$APP_PROVIDER_PARTICIPANT_ADMIN_TOKEN" $backendUserId $APP_PROVIDER_PARTY "ReadAs ActAs" "canton:3${PARTICIPANT_JSON_API_PORT_SUFFIX}"
}

# Create multiple users from arrays
create_multiple_users() {
  for i in "${!USER_IDS[@]}"; do
    echo "Creating user: ${USER_NAMES[$i]} with ID: ${USER_IDS[$i]}"
    init "${USER_IDS[$i]}" "${USER_NAMES[$i]}"
  done
}

# Generate tokens for all users (shared secret mode only)
generate_user_tokens() {
  local tokens=""
  for i in "${!USER_IDS[@]}"; do
    local token_name=$(echo "${USER_NAMES[$i]}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')_TOKEN
    local token_value=$(generate_jwt "${USER_NAMES[$i]}" "$AUTH_APP_PROVIDER_AUDIENCE")
    tokens="${tokens}  export ${token_name}=${token_value}\n"
  done
  echo -e "$tokens"
}

if [ "$AUTH_MODE" == "oauth2" ]; then
  create_multiple_users
  
  # Export user IDs for OAuth2 mode
  user_ids_exports=""
  for i in "${!USER_IDS[@]}"; do
    export_name=$(echo "${USER_NAMES[$i]}" | tr '-' '_' | tr '[:lower:]' '[:upper:]')_ID
    user_ids_exports="${user_ids_exports}  export ${export_name}=${USER_IDS[$i]}\n"
  done
  
  share_file "backend-service/on/backend-service.sh" <<EOF
  export APP_PROVIDER_PARTY=${APP_PROVIDER_PARTY}
$(echo -e "$user_ids_exports")
EOF

else
  create_multiple_users
  
  # Generate tokens for all users
  APP_PROVIDER_BACKEND_USER_TOKEN=$(generate_jwt "$AUTH_APP_PROVIDER_BACKEND_USER_NAME" "$AUTH_APP_PROVIDER_AUDIENCE")
  
  share_file "backend-service/on/backend-service.sh" <<EOF
  export APP_PROVIDER_PARTY=${APP_PROVIDER_PARTY}
  export APP_PROVIDER_BACKEND_USER_TOKEN=${APP_PROVIDER_BACKEND_USER_TOKEN}
$(generate_user_tokens)
EOF
fi