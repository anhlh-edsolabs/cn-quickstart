# Canton Network Licensing System Workflow

## Overview

The Canton Network Licensing System is a DAML-based application that manages software licenses between app providers and app users within the Canton Network ecosystem. It handles application installations, license creation, renewals, and lifecycle management using Amulet (CC) cryptocurrency for payments.

## System Architecture

### Key Parties

- **DSO (Digital System Operator)**: Issues Amulet currency and manages Canton Network rules
- **App Provider**: Software vendor offering licensed applications  
- **App User**: Customer purchasing licenses to use the applications

### Core Components

1. **[License.daml](daml/Licensing/License.daml)** - Core licensing contract with renewal and expiration logic
2. **[AppInstall.daml](daml/Licensing/AppInstall.daml)** - Application installation and user onboarding management  
3. **[Util.daml](daml/Licensing/Util.daml)** - Utility functions for metadata validation and assertions

## System Overview Diagram

```mermaid
graph TB
    subgraph "Parties"
        DSO["DSO<br/>(Digital System Operator)"]
        Provider["App Provider<br/>(Software Vendor)"]
        User["App User<br/>(Customer)"]
    end
    
    subgraph "Core Contracts"
        AppInstallReq["AppInstallRequest<br/>User requests app access"]
        AppInstall["AppInstall<br/>Accepted installation"]
        License["License<br/>Usage rights contract"]
        LicenseRenewal["LicenseRenewalRequest<br/>Renewal offer"]
        PaymentReq["AppPaymentRequest<br/>Payment for renewal"]
        AcceptedPayment["AcceptedAppPayment<br/>Confirmed payment"]
    end
    
    subgraph "External Dependencies"
        AmuletRules["AmuletRules<br/>(Canton Network)"]
        OpenMiningRound["OpenMiningRound<br/>(Canton Network)"]
        Amulet["Amulet<br/>(CC Currency)"]
    end
    
    User -->|Creates| AppInstallReq
    Provider -->|Accepts| AppInstall
    Provider -->|Creates License| License
    Provider -->|Initiates Renewal| LicenseRenewal
    LicenseRenewal -->|Creates| PaymentReq
    User -->|Pays with| Amulet
    PaymentReq -->|Becomes| AcceptedPayment
    AcceptedPayment -->|Extends| License
    
    DSO -->|Issues| Amulet
    AmuletRules -->|Governs| AcceptedPayment
    OpenMiningRound -->|Validates| AcceptedPayment
```

## Contract State Diagram

```mermaid
stateDiagram-v2
    [*] --> AppInstallRequest : User requests<br/>app installation
    AppInstallRequest --> AppInstall : Provider accepts<br/>installation request
    AppInstallRequest --> [*] : Provider rejects<br/>OR User cancels
    
    AppInstall --> License : Provider creates<br/>license with params
    AppInstall --> [*] : Either party<br/>cancels installation
    
    License --> LicenseRenewalRequest : Provider initiates<br/>renewal process
    License --> [*] : License expires<br/>(choice exercised)
    
    LicenseRenewalRequest --> AppPaymentRequest : System creates<br/>payment request
    
    AppPaymentRequest --> AcceptedAppPayment : User accepts<br/>and pays with Amulet
    AppPaymentRequest --> [*] : User rejects<br/>OR request expires
    
    AcceptedAppPayment --> License : Provider completes<br/>renewal process<br/>(extends license)
    
    LicenseRenewalRequest --> [*] : Either party<br/>cancels renewal
    
    note right of License
        License contains:
        - Expiration time
        - License number
        - Parameters/metadata
        - Provider & User parties
    end note
    
    note right of AppPaymentRequest
        Payment handles:
        - Fee amount in CC
        - Payment deadline
        - Amulet transactions
    end note
```

## Detailed Workflow Sequence

```mermaid
sequenceDiagram
    participant U as App User
    participant P as App Provider
    participant D as DSO
    participant CN as Canton Network
    
    Note over U,CN: 1. Application Installation Phase
    U->>+P: Create AppInstallRequest
    P->>P: Validate user eligibility
    P->>-U: Accept → Create AppInstall
    
    Note over U,CN: 2. License Creation Phase
    P->>+U: Create License (expires immediately)
    Note right of P: Initial license with<br/>expiration = now<br/>licenseNum = 1
    U-->>-P: License contract active
    
    Note over U,CN: 3. License Renewal Phase
    P->>+U: License_Renew choice
    Note right of P: Parameters:<br/>- Fee amount (CC)<br/>- Extension duration<br/>- Payment deadline
    
    P->>P: Create LicenseRenewalRequest
    P->>U: Create AppPaymentRequest
    U-->>-P: Renewal offer created
    
    Note over U,CN: 4. Payment Processing Phase
    U->>+CN: Get Amulet for payment
    D->>U: Issue Amulet (CC)
    U->>P: Accept payment request
    P->>CN: Submit payment to Canton
    CN->>+D: Process Amulet transaction
    D->>CN: Validate through AmuletRules
    CN-->>-P: AcceptedAppPayment created
    
    Note over U,CN: 5. License Extension Phase
    P->>+P: LicenseRenewalRequest_CompleteRenewal
    P->>CN: Collect accepted payment
    P->>P: Archive old license
    P->>U: Create extended license
    Note right of P: New expiration =<br/>max(now, old_expiration)<br/>+ extension_duration
    P-->>-U: License renewed successfully
    
    Note over U,CN: 6. Alternative Flows
    alt Payment Rejected
        U->>P: Reject AppPaymentRequest
        P->>P: Cancel LicenseRenewalRequest
    else Payment Expires
        P->>P: Expire AppPaymentRequest
        P->>P: Cancel LicenseRenewalRequest
    else License Expires
        U->>P: License_Expire choice
        Note right of U: Can be called by<br/>any signatory after<br/>expiration time
    end
```

## Data Model

```mermaid
erDiagram
    AppInstallRequest ||--o{ AppInstall : "accepts/rejects"
    AppInstall ||--o{ License : "creates licenses"
    License ||--o{ LicenseRenewalRequest : "initiates renewals"
    LicenseRenewalRequest ||--|| AppPaymentRequest : "references"
    AppPaymentRequest ||--o| AcceptedAppPayment : "becomes when paid"
    AcceptedAppPayment ||--|| License : "extends via renewal"
    
    AppInstallRequest {
        Party dso
        Party provider
        Party user
        Metadata meta
    }
    
    AppInstall {
        Party dso
        Party provider
        Party user
        Metadata meta
        Int numLicensesCreated
    }
    
    License {
        Party provider
        Party user
        Party dso
        Time expiresAt
        Int licenseNum
        LicenseParams params
    }
    
    LicenseRenewalRequest {
        Party provider
        Party user
        Party dso
        Int licenseNum
        Decimal licenseFeeCc
        RelTime licenseExtensionDuration
        ContractId reference
    }
    
    AppPaymentRequest {
        Party provider
        Party dso
        Party sender
        ReceiverAmount receiverAmounts
        Text description
        Time expiresAt
    }
    
    AcceptedAppPayment {
        Party sender
        Party provider
        Party dso
        ReceiverAmuletAmount amuletReceiverAmounts
        ContractId lockedAmulet
        Round round
        ContractId reference
    }
    
    LicenseParams {
        Metadata meta
    }
    
    Metadata {
        Map values
    }
```

## Workflow Details

### 1. Application Installation Phase

**User Onboarding Process:**

1. **User Request**: User creates `AppInstallRequest` with metadata for system correlation
2. **Provider Validation**: Provider validates user eligibility and existing installations
3. **Installation Creation**: Provider accepts request → creates `AppInstall` contract
4. **Tracking**: `AppInstall` tracks `numLicensesCreated` for each user

**Key Features:**
- Either party can cancel installation at any time
- Metadata supports integration with external systems
- Provider can associate internal user IDs with installations

**Code Example:**
```daml
-- User submits install request
requestId <- submit user.primaryParty do
  createCmd AppInstallRequest with
    dso = app.dso
    provider = app.provider.primaryParty
    user = user.primaryParty
    meta = emptyMetadata

-- Provider accepts request
submit app.provider.primaryParty do
  exerciseCmd requestId AppInstallRequest_Accept with
    meta = emptyMetadata
    installMeta = Metadata with
      values = Map.fromList [("providerUserId", "<user-id>")]
```

### 2. License Creation and Management

**License Contract Structure:**

- `expiresAt`: License expiration timestamp
- `licenseNum`: Sequential identifier for user's licenses  
- `params`: Configurable metadata for license purpose/restrictions
- Signed by both provider and user

**Initial License Creation:**
```daml
-- Provider creates initial license that expires immediately
result <- exerciseCmd installId AppInstall_CreateLicense with
  params = LicenseParams with
    meta = Metadata with
      values = Map.fromList [("licenseId", "<dummy-uuid>")]

-- License is created with expiresAt = now, forcing immediate renewal
```

### 3. License Renewal Process

**Step-by-Step Renewal:**

#### 3.1 Renewal Initiation (Provider)
- Provider exercises `License_Renew` choice
- Specifies fee amount, extension duration, payment deadline
- Creates both `LicenseRenewalRequest` and `AppPaymentRequest`

```daml
(renewalRequest, paymentRequest) <- submit provider.primaryParty do
  exerciseCmd licenseId License_Renew with
    licenseFeeCc = 20.0
    licenseExtensionDuration = days 365
    paymentAcceptanceDuration = days 1
    description = "Annual license renewal"
```

#### 3.2 Payment Processing (User)
- User obtains Amulet (CC) from DSO
- User accepts payment request with sufficient Amulet
- Canton Network processes payment through AmuletRules
- Creates `AcceptedAppPayment` contract

#### 3.3 License Extension (Provider)
- Provider exercises `LicenseRenewalRequest_CompleteRenewal`
- System validates payment matches renewal terms
- Archives old license, creates new license with extended expiration

```daml
-- Extension calculation
expiresAt = (max now license.expiresAt) `addRelTime` licenseExtensionDuration
```

### 4. Alternative Scenarios

#### Payment Rejection
- User can reject payment request using `AppPaymentRequest_Reject`
- Provider cancels renewal request with metadata reason
- Both contracts archived, license remains unchanged

#### Payment Expiration
- Provider can expire payment requests past deadline using `AppPaymentRequest_Expire`
- Automatic cleanup of renewal and payment contracts
- Balances remain unchanged

#### License Expiration
- Any signatory can expire license after expiration time using `License_Expire`
- Explicit cleanup mechanism for expired licenses

## Testing Scenarios

The comprehensive test suite in `../licensing-tests/daml/Licensing/Scripts/TestLicense.daml` demonstrates:

```mermaid
flowchart TD
    Start([Test Scenario Starts]) --> Setup[Setup Licensing App<br/>Provider, Alice, Bob, DSO]
    Setup --> Install[Alice requests App Installation<br/>Provider accepts]
    Install --> InitLicense[Provider creates initial License<br/>expiresAt = now]
    
    InitLicense --> Time1[Advance 10 days<br/>2022-01-11]
    Time1 --> Renewal1[First Renewal: $20 USD<br/>Extension: 365 days]
    Renewal1 --> Pay1[Alice pays with 64 CC<br/>Provider receives payment]
    Pay1 --> Check1[Verify: License expires 2023-01-11<br/>Provider: $220, Alice: $45]
    
    Check1 --> Time2[Advance 171 days<br/>2022-07-01 - Midyear Sale]
    Time2 --> Renewal2A[Second Renewal A: $10 USD<br/>Extension: 365 days]
    Renewal2A --> Renewal2B[Concurrent Renewal B: $10 USD<br/>Extension: 366 days]
    Renewal2B --> Pay2[Alice pays both renewals<br/>Provider receives payments]
    Pay2 --> Check2[Verify: License expires 2025-01-11<br/>Provider: $240, Alice: $65]
    
    Check2 --> Time3[Advance 183 days<br/>2022-12-31 - Year End Sale]
    Time3 --> Renewal3[Third Renewal: $10 USD<br/>Extension: 365 days]
    Renewal3 --> Reject[Alice REJECTS payment<br/>Provider cancels renewal]
    Reject --> Check3[Verify: No payment processed<br/>Balances unchanged]
    
    Check3 --> Renewal4[Fourth Renewal: $10 USD<br/>Extension: 365 days]
    Renewal4 --> Time4[Advance 10 days<br/>Payment request EXPIRES]
    Time4 --> Expire[Provider expires payment<br/>Cancels renewal request]
    Expire --> Check4[Verify: No contracts remain<br/>Balances unchanged]
    
    Check4 --> End([Test Complete])
    
    style Renewal1 fill:#e1f5fe
    style Renewal2A fill:#e8f5e8
    style Renewal2B fill:#e8f5e8
    style Renewal3 fill:#ffebee
    style Renewal4 fill:#fff3e0
    style Pay1 fill:#e1f5fe
    style Pay2 fill:#e8f5e8
    style Reject fill:#ffebee
    style Expire fill:#fff3e0
```

### Test Scenarios Covered

1. **Successful Renewal**: $20 fee, 1-year extension
2. **Concurrent Renewals**: Multiple extensions during sale periods  
3. **Payment Rejection**: User declines renewal payment
4. **Payment Expiration**: Timeout handling for expired requests

**Financial Tracking:**
- Provider balance increases with successful payments
- User balance decreases by payment amounts + transaction fees
- Failed renewals don't affect balances

## Key Design Features

### Metadata System
- Flexible key-value metadata for integration
- Size limits: max 128 entries, 8192 total characters
- Used for correlation with external systems

```daml
-- Metadata validation
enforceMetadataLimits : Metadata -> Update ()
enforceMetadataLimits (Metadata m) = do
  let numEntries = Map.size m
  unless (numEntries <= 128) $ 
    fail $ "Metadata has too many entries " <> show numEntries <> ": max 128"
  let totalSize = sum [T.length k + T.length v | (k, v) <- Map.toList m]
  unless (totalSize <= 8192) $ 
    fail $ "Metadata is too large " <> show totalSize <> ": max 8192 chars"
```

### Payment Integration
- Native Amulet (CC) payment support
- Integration with Canton Network's payment infrastructure
- Automatic handling of mining rounds and transfer contexts

### Concurrency Support
- Multiple renewal requests can be active simultaneously
- Each renewal is independent with separate payment flows
- License extensions accumulate additively

### Error Handling
- Comprehensive validation of payment amounts and timing
- Graceful handling of expired or rejected payments
- Metadata validation with clear error messages

```daml
-- Example validation
require "Actor is a signatory" (actor `elem` signatory this)
require "License is not expired yet" (now > expiresAt)
```

## Dependencies

The licensing system depends on several Canton Network components:

- **splice-amulet-0.1.9.dar**: Amulet currency and payment infrastructure
- **splice-util-0.1.3.dar**: Utility functions and common types
- **splice-wallet-payments-0.1.9.dar**: Payment processing and wallet integration

## Conclusion

This licensing system provides a robust, blockchain-based solution for software licensing with cryptocurrency payments. It demonstrates enterprise-grade features including:

- **Decentralized Trust**: Smart contracts ensure transparent, tamper-proof licensing
- **Flexible Payments**: Native cryptocurrency integration with automatic processing
- **Metadata Integration**: Support for external system correlation and business logic
- **Concurrent Operations**: Multiple renewals and complex business scenarios
- **Comprehensive Testing**: Full test coverage of success and failure scenarios

The system is designed for production use in the Canton Network ecosystem, providing a foundation for SaaS applications to implement blockchain-based licensing with confidence. 