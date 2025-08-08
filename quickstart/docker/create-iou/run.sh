#!/bin/bash
# Copyright (c) 2025, Digital Asset (Switzerland) GmbH and/or its affiliates. All rights reserved.
# SPDX-License-Identifier: 0BSD

# This script is executed by the `splice-onboarding` container. It leverages provided functions from `/app/utils`
# and the resolved environment to initiate Licensing Workflow by creating an App Install Request on behalf of the App User.
# Note: This script is intended for local development environment only and is not meant for production use.

set -eo pipefail

source /app/utils.sh

# Check if required arguments are provided
if [ $# -lt 2 ]; then
  echo "Usage: $0 <issuer_user_id> <owner_user_id> [cash_amount]"
  echo "  issuer_user_id: The User ID of the IOU issuer"
  echo "  owner_user_id: The User ID of the IOU owner"
  echo "  cash_amount: Optional cash amount (default: 100)"
  exit 1
fi

# Parse command line arguments
ISSUER_USER_ID=$1
OWNER_USER_ID=$2
CASH_AMOUNT=${3:-100}
ISSUER_ACCESS_TOKEN=$4

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
      "actAs": [
        "'$issuerParty'"
      ],
      "applicationId": "'$participantUserId'",
      "commandId": "create-iou-'$time'",
      "commands": [
        {
          "CreateCommand": {
            "templateId": "#quickstart-iou:IouTemplate.Iou:IouHolding",
            "createArguments": {
              "issuer": "'$issuerParty'",
              "owner": "'$ownerParty'",
              "amount": "'$cash'",
              "currency": "USD",
              "observers": []
            }
          }
        }
      ]
    }'
    # --data-raw '{
    #     "commands": [
    #       {
    #         "CreateCommand": {
    #           "templateId": "#quickstart-iou:IouTemplate.Iou:IouHolding",
    #           "createArguments": {
    #             "issuer": "'$issuerParty'",
    #             "owner": "'$ownerParty'",
    #             "cash": '$cash'
    #           }
    #         }
    #       }
    #     ],
    #     "workflowId": "create-iou",
    #     "applicationId": "'$participantUserId'",
    #     "commandId": "create-iou-'$time'",
    #     "deduplicationPeriod": {
    #       "Empty": {}
    #     },
    #     "actAs": [
    #       "'$issuerParty'"
    #     ],
    #     "readAs": [
    #       "'$issuerParty'"
    #     ],
    #     "submissionId": "create-iou",
    #     "disclosedContracts": [],
    #     "domainId": "",
    #     "packageIdSelectionPreference": []
    # }'
}

echo "AUTH MODE: $AUTH_MODE"
if [ "$AUTH_MODE" == "oauth2" ]; then

  # Use the existing APP_USER environment variables for authentication
  APP_USER_PARTICIPANT_ADMIN_TOKEN=$(get_admin_token $AUTH_APP_USER_VALIDATOR_CLIENT_SECRET $AUTH_APP_USER_VALIDATOR_CLIENT_ID $AUTH_APP_USER_TOKEN_URL)

  echo "APP_USER_PARTICIPANT_ADMIN_TOKEN: $APP_USER_PARTICIPANT_ADMIN_TOKEN"
  echo "--------------------------------"
  
  # Get party IDs from the provided User IDs
  export IOU_ISSUER_PARTY=$(get_user_party "$APP_USER_PARTICIPANT_ADMIN_TOKEN" "$ISSUER_USER_ID" "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")
  export IOU_OWNER_PARTY=$(get_user_party "$APP_USER_PARTICIPANT_ADMIN_TOKEN" "$OWNER_USER_ID" "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")

  echo "IOU_ISSUER_PARTY: $IOU_ISSUER_PARTY"
  echo "IOU_OWNER_PARTY: $IOU_OWNER_PARTY"

  create_iou "$ISSUER_ACCESS_TOKEN" "$IOU_ISSUER_PARTY" "$IOU_OWNER_PARTY" "$CASH_AMOUNT" $AUTH_APP_USER_WALLET_ADMIN_USER_ID "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}"

else
  # Use the existing APP_USER environment variables for authentication
  export APP_USER_PARTICIPANT_ADMIN_TOKEN=$(generate_jwt "$AUTH_APP_USER_VALIDATOR_USER_NAME" "$AUTH_APP_USER_AUDIENCE")
  
  APP_USER_WALLET_ADMIN_TOKEN=$(generate_jwt "$AUTH_APP_USER_WALLET_ADMIN_USER_NAME" "$AUTH_APP_USER_AUDIENCE")

  echo "APP_USER_PARTICIPANT_ADMIN_TOKEN: $APP_USER_PARTICIPANT_ADMIN_TOKEN"
  echo "APP_USER_WALLET_ADMIN_TOKEN: $APP_USER_WALLET_ADMIN_TOKEN"
  echo "--------------------------------"

  # Get party IDs from the provided User IDs
  export IOU_ISSUER_PARTY=$(get_user_party "$APP_USER_PARTICIPANT_ADMIN_TOKEN" "$ISSUER_USER_ID" "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")
  export IOU_OWNER_PARTY=$(get_user_party "$APP_USER_PARTICIPANT_ADMIN_TOKEN" "$OWNER_USER_ID" "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}")

  create_iou "$ISSUER_ACCESS_TOKEN" "$IOU_ISSUER_PARTY" "$IOU_OWNER_PARTY" "$CASH_AMOUNT" $AUTH_APP_USER_WALLET_ADMIN_USER_NAME "canton:2${PARTICIPANT_JSON_API_PORT_SUFFIX}"
fi

