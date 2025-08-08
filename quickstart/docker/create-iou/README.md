# Create IOU Script

This script creates an IOU (I Owe You) contract between two parties using the Canton JSON API v2.

## Usage

### Via Makefile (Recommended)

```bash
# Basic usage with default cash amount (100)
make create-iou ISSUER_USER_ID=<issuer_user_id> OWNER_USER_ID=<owner_user_id> ISSUER_ACCESS_TOKEN=<access_token>

# With custom cash amount
make create-iou ISSUER_USER_ID=<issuer_user_id> OWNER_USER_ID=<owner_user_id> CASH_AMOUNT=<amount> ISSUER_ACCESS_TOKEN=<access_token>
```

### Examples

```bash
# Create an IOU where alice owes bob 500 cash
make create-iou ISSUER_USER_ID=alice OWNER_USER_ID=bob CASH_AMOUNT=500 ISSUER_ACCESS_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...

# Create an IOU where user1 owes user2 100 cash (default amount)
make create-iou ISSUER_USER_ID=user1 OWNER_USER_ID=user2 ISSUER_ACCESS_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...

# Using UUIDs for User IDs
make create-iou ISSUER_USER_ID=4d039cce-796b-4cff-96ed-70e777004549 OWNER_USER_ID=25a7c154-7afc-4adc-9549-f2ccc9748070 CASH_AMOUNT=500 ISSUER_ACCESS_TOKEN=eyJhbGciOiJSUzI1NiIsInR5cCI6IkpXVCJ9...
```

### Direct Script Execution

You can also run the script directly in the container:

```bash
# Run the container and execute the script with parameters
docker compose -f docker/create-iou/compose.yaml run --rm container /app/scripts/on/create-iou.sh <issuer_user_id> <owner_user_id> [cash_amount] <issuer_access_token>
```

## Parameters

- `ISSUER_USER_ID`: The User ID of the party issuing the IOU (the debtor)
- `OWNER_USER_ID`: The User ID of the party who will own the IOU (the creditor)
- `CASH_AMOUNT`: (Optional) The amount of cash in the IOU. Defaults to 100 if not specified.
- `ISSUER_ACCESS_TOKEN`: **Required** - The OAuth2 access token for the issuer user to authenticate the request

## How it Works

1. **Authentication**: The script uses the provided `ISSUER_ACCESS_TOKEN` for authentication
2. **Party Resolution**: It looks up the party IDs for the provided User IDs using the Canton JSON API v2
3. **Fallback Handling**: If party resolution fails, it uses the User ID directly as the party ID
4. **Contract Creation**: It creates an IOU contract with the specified parameters using the correct template ID format
5. **Authorization**: The IOU is created on behalf of the issuer party with the provided access token

## Technical Details

### Template ID Format
The script uses the correct Canton JSON API v2 template ID format:
```
<packageId>:<Module>.<Template>
```

For example: `d15f5886b97bba290bfc66cf47849409db8f81aa321fc80d2fb423edd8eac2e6:Iou.Iou`

### Authentication
- Uses the provided `ISSUER_ACCESS_TOKEN` for authentication
- Supports OAuth2 access tokens for secure API access
- Handles token validation and authorization automatically

### Party ID Resolution
- Attempts to resolve User IDs to party IDs via the Canton JSON API
- Falls back to using User IDs directly if resolution fails
- Provides warning messages for debugging purposes

## Requirements

- The application must be running (`make start`)
- The specified User IDs must exist in the system
- The issuer party must have the necessary permissions to create IOU contracts
- A valid OAuth2 access token must be provided for the issuer user

## Error Handling

The script provides comprehensive error handling for:

- **Missing Parameters**: Validates required parameters and provides usage instructions
- **Authentication Failures**: Handles OAuth2 token validation errors
- **Party Resolution Issues**: Gracefully handles cases where User ID to party ID resolution fails
- **Network Connectivity**: Provides clear error messages for connection issues
- **Template ID Errors**: Uses the correct format to avoid template ID parsing errors
- **JSON API Errors**: Handles Canton JSON API v2 specific error responses

### Common Error Scenarios

1. **403 Forbidden**: Authentication or permission issues with the access token
2. **400 Bad Request**: Invalid template ID format or malformed JSON
3. **Connection Refused**: Canton service not running or network issues
4. **Party Not Found**: User ID doesn't exist or party resolution failed
5. **Missing Access Token**: Required `ISSUER_ACCESS_TOKEN` parameter not provided

## Troubleshooting

### If you get template ID errors:
- Ensure the correct package ID is being used
- Verify the template ID format uses dots (`.`) not colons (`:`) between module and template names
- Check that the IOU package is properly deployed

### If you get authentication errors:
- Verify the `ISSUER_ACCESS_TOKEN` is valid and not expired
- Check that the token has proper permissions for the issuer user
- Ensure the Canton service is running and accessible

### If you get party resolution errors:
- Verify the User IDs exist in the system
- Check that the access token has proper permissions
- The script will automatically fall back to using User IDs as party IDs

### If you get missing parameter errors:
- Ensure all required parameters are provided: `ISSUER_USER_ID`, `OWNER_USER_ID`, and `ISSUER_ACCESS_TOKEN`
- Check the parameter names and values are correct

## Recent Changes

- **Access Token Authentication**: Now requires `ISSUER_ACCESS_TOKEN` parameter for secure authentication
- **Dynamic Parameter Support**: Script accepts User IDs and access token as command-line arguments
- **Improved Authentication**: Uses provided access token instead of generating tokens internally
- **Template ID Fix**: Corrected the template ID format to use dots instead of colons
- **Enhanced Error Handling**: Added comprehensive error messages and fallback mechanisms
- **Makefile Integration**: Updated Makefile target with proper parameter validation including access token requirement 