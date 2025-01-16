// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlEnumerableUpgradeable.sol";

import "./interfaces/ISymmioPauseController.sol";

contract PauseController is 
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
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(GLOBAL_PAUSER_ROLE, globalPauser);
        _setupRole(LIQUIDATION_PAUSER_ROLE, liquidationPauser);
        _setupRole(ACCOUNTING_PAUSER_ROLE, accountingPauser);
        _setupRole(PARTYA_PAUSER_ROLE, partyAPauser);
        _setupRole(PARTYB_PAUSER_ROLE, partyBPauser);
        _setupRole(SUSPENDER_ROLE, suspender);
        _setupRole(UNSUSPENDER_ROLE, unsuspender);

        // symmio address
        symmioAddress = _symmioAddress;
    }

    function setSymmioAddress(address addr) external onlyRole(DEFAULT_ADMIN_ROLE) {
        emit SetSymmioAddress(symmioAddress, addr);
        symmioAddress = addr;
    }

    function pauseGlobal() external onlyRole(GLOBAL_PAUSER_ROLE) {
        ISymmioPauseController(symmioAddress).pauseGlobal();
        emit GlobalPaused(msg.sender);
    }

    function pauseLiquidation() external onlyRole(LIQUIDATION_PAUSER_ROLE) {
        ISymmioPauseController(symmioAddress).pauseLiquidation();
        emit LiquidationPaused(msg.sender);
    }

    function pauseAccounting() external onlyRole(ACCOUNTING_PAUSER_ROLE) {
        ISymmioPauseController(symmioAddress).pauseAccounting();
        emit AccountingPaused(msg.sender);
    }

    function pausePartyAActions() external onlyRole(PARTYA_PAUSER_ROLE) {
        ISymmioPauseController(symmioAddress).pausePartyAActions();
        emit PartyAPaused(msg.sender);
    }

    function pausePartyBActions() external onlyRole(PARTYB_PAUSER_ROLE) {
        ISymmioPauseController(symmioAddress).pausePartyBActions();
        emit PartyBPaused(msg.sender);
    }

    function suspendAddress(address user) external onlyRole(SUSPENDER_ROLE) {
        ISymmioPauseController(symmioAddress).suspendedAddress(user);
        emit AddressSuspended(user, msg.sender);
    }

    function unsuspendAddress(address user) external onlyRole(UNSUSPENDER_ROLE) {
        ISymmioPauseController(symmioAddress).unsuspendedAddress(user);
        emit AddressUnsuspended(user, msg.sender);
    }
}
