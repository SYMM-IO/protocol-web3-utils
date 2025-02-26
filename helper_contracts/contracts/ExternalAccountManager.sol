// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity ^0.8.18;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "./interfaces/ISymmio.sol";
import "./interfaces/IMultiAccount.sol";

/**
 * @title ExternalAccountManager
 * @notice This upgradable, pausable contract allows an admin to temporarily unsuspend an account,
 * perform a withdrawal via the MultiAccount contract, and then re-suspend the account.
 * It uses reentrancy protection for extra security.
 */
contract ExternalAccountManager is
    Initializable,
    PausableUpgradeable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    ISymmio public symmio;
    IMultiAccount public multiAccount;

    /**
     * @dev Initializes the ExternalAccountManager contract.
     * @param admin The admin address that will be granted DEFAULT_ADMIN_ROLE and ADMIN_ROLE.
     * @param _symmioAddress The address of the deployed ControlFacet contract.
     * @param _multiAccountAddress The address of the deployed MultiAccount contract.
     */
    function initialize(
        address admin,
        address _symmioAddress,
        address _multiAccountAddress
    ) public initializer {
        __Pausable_init();
        __AccessControl_init();
        __ReentrancyGuard_init();

        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(ADMIN_ROLE, admin);

        symmio = ISymmio(_symmioAddress);
        multiAccount = IMultiAccount(_multiAccountAddress);
    }

    /**
     * @notice Facilitates the withdrawal process from a suspended account.
     * @dev This function unsuspends the account, calls MultiAccount to withdraw the funds,
     * and then suspends the account again. Reentrancy is prevented via a guard.
     *
     * Requirements:
     * - The caller must have the ADMIN_ROLE.
     * - The contract must not be paused.
     *
     * @param account The address of the account (the "suspended" user) to withdraw from.
     * @param amount The amount to withdraw.
     * @param recipient The address where the withdrawn funds will be sent.
     */
    function facilitatedWithdraw(
        address account,
        uint256 amount,
        address recipient
    ) external nonReentrant whenNotPaused onlyRole(ADMIN_ROLE) {
        // Requires that this contract has the SUSPENDER_ROLE on the SYMMIO ControlFacet.
        symmio.unsuspendedAddress(account);

        // Note: the MultiAccount contract must have
        // granted this external contract the appropriate delegated access (or be the owner)
        // for the withdrawTo function selector.
        bytes memory callData = abi.encodeWithSignature("withdrawTo(address,uint256)", recipient, amount);
        bytes[] memory callDatas = new bytes[](1);
        callDatas[0] = callData;
        multiAccount._call(account, callDatas);

        // Requires that this contract has the DEFAULT_ADMIN_ROLE on the SYMMIO ControlFacet.
        symmio.suspendedAddress(account);
    }

    /**
     * @notice Updates the address of the ControlFacet contract.
     * @param _symmioAddress The new ControlFacet contract address.
     */
    function updateControlFacet(address _symmioAddress) external onlyRole(ADMIN_ROLE) {
        symmio = ISymmio(_symmioAddress);
    }

    /**
     * @notice Updates the address of the MultiAccount contract.
     * @param _multiAccountAddress The new MultiAccount contract address.
     */
    function updateMultiAccount(address _multiAccountAddress) external onlyRole(ADMIN_ROLE) {
        multiAccount = IMultiAccount(_multiAccountAddress);
    }

    /**
     * @notice Pauses the ExternalAccountManager contract.
     */
    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    /**
     * @notice Unpauses the ExternalAccountManager contract.
     */
    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}
