# Decentralized Disaster Relief Fund Manager

## Project Overview

The Decentralized Disaster Relief Fund Manager is a smart contract system designed to manage disaster relief funds in a transparent, automated, and accountable manner. This system allows donors to contribute funds to specific causes and ensures their allocation to verified recipients based on predefined criteria.

## Key Features

1. **Donor Contribution Tracking**
   - Transparent tracking of all donations on the blockchain
   - Ability for donors to specify causes to fund

2. **Automated Fund Disbursement**
   - Release of funds to recipients based on verified criteria
   - Time-locked mechanism for fund disbursement after verification

3. **Recipient Verification and Monitoring**
   - Incorporation of verification process for relief requests
   - Monitoring of fund usage through required reporting

4. **Transparent Fund Management**
   - Real-time tracking of total funds and disbursements for each cause
   - Ability to view individual donor contributions and beneficiary receipts

## Smart Contract Functions

### Donor Functions
- `donate`: Allows donors to contribute funds to a specific cause
- `get-donation`: Retrieves the donation amount for a specific donor and cause

### Relief Manager Functions
- `request-fund`: Enables beneficiaries to submit fund requests
- `approve-request`: Allows the contract owner to approve fund requests

### Disbursement Functions
- `disburse-funds`: Releases approved funds to verified beneficiaries

### Read-only Functions
- `get-cause-details`: Retrieves details about a specific cause
- `get-fund-request`: Gets information about a specific fund request
- `get-beneficiary-details`: Retrieves details about a beneficiary

## Getting Started

1. Clone this repository
2. Install the Clarity CLI and set up a local Stacks blockchain for testing
3. Deploy the smart contract to your local blockchain
4. Interact with the contract using the provided functions

## Testing

To test the smart contract:

1. Use the Clarity CLI to call the various functions
2. Verify that donations, fund requests, and disbursements are working as expected
3. Check that only the contract owner can approve requests

## Security Considerations

- The contract includes access control to ensure only the owner can approve fund requests
- Funds are held in the contract until explicitly disbursed
- Beneficiary verification is required before fund disbursement

## Future Enhancements

- Integration with real-world data oracles for automated disaster reporting
- Implementation of a refund mechanism for unused funds
- Addition of multi-signature approval for increased security

## Contributing

Contributions to improve the Decentralized Disaster Relief Fund Manager are welcome. Please submit pull requests or open issues to discuss proposed changes.

## License

This project is licensed under the MIT License.
