# IoT Device Management Platform

A comprehensive decentralized platform for IoT device registration, data monetization, access control, network management, and maintenance tracking. This smart contract enables secure peer-to-peer IoT data transactions with a built-in reputation system.

## Overview

This smart contract provides a complete infrastructure for managing IoT devices on the blockchain, including device registration, data storage, access control, network creation, and maintenance scheduling. The platform allows device owners to monetize their data while providing secure access to authorized users.

## Features

### Device Management
- **Device Registration**: Register IoT devices with metadata, location, and pricing information
- **Configuration Updates**: Modify device settings, firmware versions, and pricing
- **Status Management**: Control device operational status (active, inactive, maintenance, offline)
- **Reputation Tracking**: Built-in reputation scoring system for devices

### Data Management
- **Secure Data Storage**: Store device data with content hashes and integrity verification
- **Data Classification**: Categorize data types with metadata
- **Sensor Reading Storage**: Store numerical sensor readings with validation
- **Access Subscriptions**: Purchase time-based access to device data

### Access Control
- **Permission Levels**: Three-tier access system (read, write, admin)
- **Time-based Access**: Grant temporary access permissions with expiration
- **Subscription Management**: Automated subscription handling with payments

### Network Management
- **Device Networks**: Create and manage collections of related devices
- **Membership Control**: Public or private network access with membership fees
- **Network Administration**: Centralized management with role-based permissions

### Maintenance Management
- **Maintenance Scheduling**: Schedule and track device maintenance activities
- **Cost Tracking**: Monitor maintenance costs and completion status
- **Status Updates**: Automatic status changes during maintenance periods

## Contract Constants

### Device Types
- `device-type-sensor` (1): Sensor devices
- `device-type-actuator` (2): Actuator devices  
- `device-type-gateway` (3): Gateway devices
- `device-type-hybrid` (4): Hybrid devices

### Device Status
- `device-status-active` (1): Device is operational
- `device-status-inactive` (2): Device is inactive
- `device-status-maintenance` (3): Device under maintenance
- `device-status-offline` (4): Device is offline

### Access Levels
- `access-level-read` (1): Read-only access
- `access-level-write` (2): Read and write access
- `access-level-admin` (3): Full administrative access

## Key Functions

### Device Registration
```clarity
(register-iot-device device-id device-type location metadata firmware-version data-price control-price)
```
Register a new IoT device with the platform.

### Data Storage
```clarity
(store-device-data-record device-id content-hash data-type sensor-reading payload-size verification-hash)
```
Store new data records from registered devices.

### Access Control
```clarity
(grant-device-access-permission device-id user permission-level duration)
(revoke-device-access-permission device-id user)
```
Manage access permissions for devices.

### Data Subscription
```clarity
(purchase-data-access-subscription device-id duration)
```
Purchase subscription-based access to device data.

### Network Management
```clarity
(create-device-network network-id name description public-access membership-fee)
(join-device-to-network network-id device-id)
```
Create and manage device networks.

### Maintenance
```clarity
(schedule-device-maintenance device-id start-time category notes cost)
(complete-device-maintenance device-id maintenance-id final-cost)
```
Schedule and complete device maintenance activities.

## Validation Rules

### String Length Limits
- Device metadata: 500 characters maximum
- Firmware version: 20 characters maximum
- Descriptions: 300 characters maximum
- Names and locations: 100 characters maximum

### Pricing
- Maximum price amount: 1,000,000,000 units
- Platform commission: 2.5% (250 basis points)

### Data Integrity
- Hash buffers must be exactly 32 bytes
- Sensor readings must be within valid integer range

## Error Codes

- `ERR-UNAUTHORIZED-ACCESS` (1001): User lacks required permissions
- `ERR-DEVICE-NOT-FOUND` (1002): Device not registered
- `ERR-DEVICE-ALREADY-REGISTERED` (1003): Device already exists
- `ERR-INVALID-INPUT-PARAMETERS` (1004): Invalid function parameters
- `ERR-INSUFFICIENT-PAYMENT-AMOUNT` (1005): Insufficient payment
- `ERR-DEVICE-CURRENTLY-OFFLINE` (1006): Device is offline
- `ERR-ACCESS-PERMISSION-DENIED` (1007): Access denied
- `ERR-SUBSCRIPTION-HAS-EXPIRED` (1011): Subscription expired

## Data Structures

### Device Registry
Stores core device information including owner, type, status, location, metadata, pricing, and reputation.

### Data Repository
Stores device data records with content hashes, classifications, sensor readings, and integrity verification.

### Access Permissions
Manages user permissions with levels, expiration times, and usage tracking.

### Network Registry
Stores network information including administrators, member counts, and access policies.

### Maintenance Log
Tracks scheduled and completed maintenance activities with costs and notes.

## Security Features

- **Owner Verification**: Only device owners can modify device settings
- **Access Control**: Granular permission system with time-based expiration
- **Input Validation**: Comprehensive validation of all user inputs
- **Payment Protection**: Secure payment handling with commission distribution
- **Data Integrity**: Hash-based verification for all stored data

## Platform Economics

The platform operates on a commission-based model where:
- Device owners set their own data and control access prices
- The platform takes a 2.5% commission on all transactions
- Device owners receive 97.5% of subscription payments
- Network administrators can set membership fees

## Usage Notes

- Contract operations can be paused by the administrator for maintenance
- All timestamps use block height for consistency
- Device reputation scores start at 100 and can be updated based on performance
- Subscription payments are automatically distributed between device owners and the platform
- Maintenance activities automatically update device status

## Requirements

- Stacks blockchain environment
- STX tokens for transaction fees and payments
- Valid principal addresses for all participants