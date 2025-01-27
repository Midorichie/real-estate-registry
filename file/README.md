# Decentralized Real Estate Title Registry

A blockchain-based system for registering and verifying property ownership records on the Stacks blockchain.

## Overview

This smart contract system provides a decentralized solution for managing real estate titles, ensuring:
- Immutable property ownership records
- Transparent transaction history
- Reduced fraud through blockchain verification
- Simplified property transfers

## Technical Architecture

### Smart Contracts
- `real-estate-registry.clar`: Main contract handling property registration and ownership
  - Property registration with unique IDs
  - Ownership tracking and transfer
  - Historical transaction records
  - Status management

### Security Features
- Principal-based authorization
- Error handling for common edge cases
- Data validation for property registration
- Immutable transaction history

## Development Setup

1. Install dependencies:
```bash
curl -sL https://install.clarinet.sh | sh
clarinet new real-estate-registry
cd real-estate-registry
```

2. Initialize development environment:
```bash
clarinet integrate
```

3. Run tests:
```bash
clarinet test
```

## Contract Interaction

### Register a New Property
```clarity
(contract-call? .real-estate-registry register-property 
    "property123" 
    "123 Main St, coordinates: 40.7128° N, 74.0060° W")
```

### Query Property Details
```clarity
(contract-call? .real-estate-registry get-property-details "property123")
```

## Testing

The project includes comprehensive tests covering:
- Property registration
- Ownership verification
- Invalid operation handling
- Access control

## Security Considerations

1. Principal Authentication
   - Only authorized principals can modify property records
   - Ownership verification before transfers

2. Data Validation
   - Input sanitization for property details
   - Size limits on string inputs
   - Transaction validity checks

## Future Enhancements

1. Phase 2:
   - Property transfer functionality
   - Multi-signature support
   - Document hash storage

2. Phase 3:
   - Integration with legal framework
   - API for external systems
   - Enhanced query capabilities
