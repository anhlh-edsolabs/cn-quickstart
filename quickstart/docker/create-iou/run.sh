#!/bin/bash
# Copyright (c) 2025, Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: 0BSD

# This script is executed by the `splice-onboarding` container. It leverages provided functions from `/app/utils`
# and the resolved environment to initiate Licensing Workflow by creating an App Install Request on behalf of the App User.
# Note: This script is intended for local development environment only and is not meant for production use.

set -eo pipefail

source /app/utils.sh

create_iou() {
  local token=$1
  local issuerParty=$2
  local ownerParty=$3
  local cash=$4
  local participantUserId=$5
  local participant=$6

  # Add a timestamp for a unique command ID to allow resubmission
  local time="$(date +%s%N)"

  echo "create_iou $issuerParty $ownerParty $cash $participant" >&2

  curl_check "http://$participant/v2/commands/submit-and-wait" "$token" "application/json" \
    --data-raw '{
        "commands": [
          {
            "CreateCommand": {
              "templateId": "#quickstart-iou:Iou.Iou",
              "createArguments": {
                "issuer": "'$issuerParty'",
                "owner": "'$ownerParty'",
                "cash": "'$cash'",
                "meta": {
                  "values": []
                }
              }
            }
          }
        ],
        "workflowId": "create-iou",
        "applicationId": "'$participantUserId'",
        "commandId": "create-iou-'$time'",
        "deduplicationPeriod": {
          "Empty": {}
        },
        "actAs": [
          "'$issuerParty'"
        ],
        "readAs": [
          "'$issuerParty'"
        ],
        "submissionId": "create-iou",
        "disclosedContracts": [],
        "domainId": "",
        "packageIdSelectionPreference": []
    }'
}

echo "AUTH MODE: $AUTH_MODE"
if [ "$AUTH_MODE" == "oauth2" ]; then

  IOU_ISSUER_WALLET_ADMIN_TOKEN=$(get_user_token $AUTH_IOU_ISSUER_WALLET_ADMIN_USER_NAME $AUTH_IOU_ISSUER_WALLET_ADMIN_USER_PASSWORD $AUTH_IOU_ISSUER_AUTO_CONFIG_CLIENT_ID $AUTH_IOU_ISSUER_TOKEN_URL)
  IOU_OWNER_WALLET_ADMIN_TOKEN=$(get_user_token $AUTH_IOU_OWNER_WALLET_ADMIN_USER_NAME $AUTH_IOU_OWNER_WALLET_ADMIN_USER_PASSWORD $AUTH_IOU_OWNER_AUTO_CONFIG_CLIENT_ID $AUTH_IOU_OWNER_TOKEN_URL)
  # DSO_PARTY=$(get_dso_party_id "$APP_USER_WALLET_ADMIN_TOKEN" "splice:2${VALIDATOR_ADMIN_API_PORT_SUFFIX}")

  echo "IOU_ISSUER_WALLET_ADMIN_TOKEN: $IOU_ISSUER_WALLET_ADMIN_TOKEN"
  echo "IOU_OWNER_WALLET_ADMIN_TOKEN: $IOU_OWNER_WALLET_ADMIN_TOKEN"
  
  export IOU_ISSUER_PARTY=$(get_user_party "$IOU_ISSUER_WALLET_ADMIN_TOKEN" $AUTH_IOU_ISSUER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")
  export IOU_OWNER_PARTY=$(get_user_party "$IOU_OWNER_WALLET_ADMIN_TOKEN" $AUTH_IOU_OWNER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")

  create_iou "$IOU_ISSUER_WALLET_ADMIN_TOKEN" $IOU_ISSUER_PARTY $IOU_OWNER_PARTY $AUTH_APP_USER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}"

else
  # APP_USER_WALLET_ADMIN_TOKEN=$(generate_jwt "$AUTH_APP_USER_WALLET_ADMIN_USER_NAME" "$AUTH_APP_USER_AUDIENCE")
  IOU_ISSUER_WALLET_ADMIN_TOKEN=$(generate_jwt "$AUTH_IOU_ISSUER_WALLET_ADMIN_USER_NAME" "$AUTH_APP_USER_AUDIENCE")
  IOU_OWNER_WALLET_ADMIN_TOKEN=$(generate_jwt "$AUTH_IOU_OWNER_WALLET_ADMIN_USER_NAME" "$AUTH_APP_USER_AUDIENCE")

  echo "IOU_ISSUER_WALLET_ADMIN_TOKEN: $IOU_ISSUER_WALLET_ADMIN_TOKEN"
  echo "IOU_OWNER_WALLET_ADMIN_TOKEN: $IOU_OWNER_WALLET_ADMIN_TOKEN"

  export IOU_ISSUER_PARTY=$(get_user_party "$IOU_ISSUER_WALLET_ADMIN_TOKEN" $AUTH_IOU_ISSUER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")
  export IOU_OWNER_PARTY=$(get_user_party "$IOU_OWNER_WALLET_ADMIN_TOKEN" $AUTH_IOU_OWNER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")

  create_iou "$IOU_ISSUER_WALLET_ADMIN_TOKEN" $IOU_ISSUER_PARTY $IOU_OWNER_PARTY $AUTH_APP_USER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}"

  # DSO_PARTY=$(get_dso_party_id "$APP_USER_WALLET_ADMIN_TOKEN" "splice:2${VALIDATOR_ADMIN_API_PORT_SUFFIX}")

  # create_iou "$APP_USER_WALLET_ADMIN_TOKEN" $DSO_PARTY $APP_USER_PARTY $APP_PROVIDER_PARTY $AUTH_APP_USER_WALLET_ADMIN_USER_NAME "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}"
fi

