// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./interfaces/ISymmio.sol";

contract ExternalSymmioController is 
    Initializable,
    AccessControlEnumerableUpgradeable
{
    bytes32 public constant GLOBAL_PAUSER_ROLE = keccak256("GLOBAL_PAUSER_ROLE");
    bytes32 public constant LIQUIDATION_PAUSER_ROLE = keccak256("LIQUIDATION_PAUSER_ROLE");
    bytes32 public constant ACCOUNTING_PAUSER_ROLE = keccak256("ACCOUNTING_PAUSER_ROLE");
    bytes32 public constant PARTYA_PAUSER_ROLE = keccak256("PARTYA_PAUSER_ROLE");
    bytes32 public constant PARTYB_PAUSER_ROLE = keccak256("PARTYB_PAUSER_ROLE");
    bytes32 public constant SUSPENDER_ROLE = keccak256("SUSPENDER_ROLE");
    bytes32 public constant UNSUSPENDER_ROLE = keccak256("UNSUSPENDER_ROLE");

    event SetSymmioAddress(address oldSymmioAddress, address newSymmioAddress);

    event GlobalPaused(address indexed pauser);
    event LiquidationPaused(address indexed pauser);
    event AccountingPaused(address indexed pauser);
    event PartyAPaused(address indexed pauser);
    event PartyBPaused(address indexed pauser);

    event AddressSuspended(address indexed suspendedUser, address indexed suspender);
    event AddressUnsuspended(address indexed unsuspendedUser, address indexed unsuspender);

    address public symmioAddress;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    /// @dev Replaces the constructor in upgradeable contracts.
    function initialize(
        address _symmioAddress,

        address globalPauser,
        address liquidationPauser,
        address accountingPauser,
        address partyAPauser,
        address partyBPauser,
        address suspender,
        address unsuspender
    ) external initializer {
        // Initialize parent contracts
        __AccessControlEnumerable_init();

        // Grant roles
        grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        grantRole(GLOBAL_PAUSER_ROLE, globalPauser);
        grantRole(LIQUIDATION_PAUSER_ROLE, liquidationPauser);
        grantRole(ACCOUNTING_PAUSER_ROLE, accountingPauser);
        grantRole(PARTYA_PAUSER_ROLE, partyAPauser);
        grantRole(PARTYB_PAUSER_ROLE, partyBPauser);
        grantRole(SUSPENDER_ROLE, suspender);
        grantRole(UNSUSPENDER_ROLE, unsuspender);

        // symmio address
        symmioAddress = _symmioAddress;
    }

    function setSymmioAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit SetSymmioAddress(symmioAddress, addr);
        symmioAddress = addr;
    }

    function pauseGlobal() external onlyRole(GLOBAL_PAUSER_ROLE) {
        ISymmio(symmioAddress).pauseGlobal();
        emit GlobalPaused(msg.sender);
    }

    function pauseLiquidation() external onlyRole(LIQUIDATION_PAUSER_ROLE) {
        ISymmio(symmioAddress).pauseLiquidation();
        emit LiquidationPaused(msg.sender);
    }

    function pauseAccounting() external onlyRole(ACCOUNTING_PAUSER_ROLE) {
        ISymmio(symmioAddress).pauseAccounting();
        emit AccountingPaused(msg.sender);
    }

    function pausePartyAActions() external onlyRole(PARTYA_PAUSER_ROLE) {
        ISymmio(symmioAddress).pausePartyAActions();
        emit PartyAPaused(msg.sender);
    }

    function pausePartyBActions() external onlyRole(PARTYB_PAUSER_ROLE) {
        ISymmio(symmioAddress).pausePartyBActions();
        emit PartyBPaused(msg.sender);
    }

    function suspendAddress(address user) external onlyRole(SUSPENDER_ROLE) {
        ISymmio(symmioAddress).suspendedAddress(user);
        emit AddressSuspended(user, msg.sender);
    }

    function unsuspendAddress(address user) external onlyRole(UNSUSPENDER_ROLE) {
        ISymmio(symmioAddress).unsuspendedAddress(user);
        emit AddressUnsuspended(user, msg.sender);
    }
}
