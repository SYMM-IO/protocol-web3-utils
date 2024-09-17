// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./interfaces/ISymmio.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract LimitedSymbolAdder is AccessControlEnumerable, Pausable {
    address public symmioAddress;
    uint256 public dailyLimit;
    uint256 public symbolsAddedToday;
    uint256 public lastResetTimestamp;

    // Define roles
    bytes32 public constant OPERATOR_ROLE = keccak256("OPERATOR_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

    // Define custom errors
    error DailyLimitExceeded(uint256 attempted, uint256 remaining);
    error InvalidSymbolsList();

    // Define events
    event DailyLimitUpdated(uint256 newDailyLimit);

    /**
     * @dev Initializes the contract by setting the Symmio address, admin, operator, and daily limit.
     * Grants DEFAULT_ADMIN_ROLE to the admin.
     * Calls `setDailyLimit` to initialize the daily limit and emit an event.
     * @param _symmioAddress The address of the Symmio contract.
     * @param admin The address of the contract administrator.
     * @param operator The address of the operator.
     * @param _dailyLimit The maximum number of symbols that can be added per day.
     */
    constructor(
        address _symmioAddress,
        address admin,
        address operator,
        uint256 _dailyLimit
    ) {
        symmioAddress = _symmioAddress;
        lastResetTimestamp = block.timestamp;

        // Set up roles
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(OPERATOR_ROLE, operator);
        _setupRole(PAUSER_ROLE, admin);
        _setupRole(UNPAUSER_ROLE, admin);

        setDailyLimit(_dailyLimit);
    }

    /**
     * @dev Pauses the contract, preventing `addSymbols` from being called.
     * Can only be called by accounts with the PAUSER_ROLE.
     */
    function pause() external whenNotPaused onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpauses the contract, allowing `addSymbols` to be called.
     * Can only be called by accounts with the UNPAUSER_ROLE.
     */
    function unpause() external whenPaused onlyRole(UNPAUSER_ROLE) {
        _unpause();
    }

    /**
     * @dev Adds new symbols to the Symmio contract, with a daily limit.
     * Resets the count if a new day has started.
     * Can only be called by accounts with the OPERATOR_ROLE.
     * @param symbols The array of symbols to be added.
     */
    function addSymbols(
        ISymmio.Symbol[] memory symbols
    ) external whenNotPaused onlyRole(OPERATOR_ROLE) {
        // Reset the counter if a new day has started
        if (block.timestamp >= lastResetTimestamp + 1 days) {
            symbolsAddedToday = 0;
            lastResetTimestamp = block.timestamp;
        }

        uint256 symbolsLength = symbols.length;

        if (symbolsLength == 0) {
            revert InvalidSymbolsList();
        }

        if (symbolsAddedToday + symbolsLength > dailyLimit) {
            revert DailyLimitExceeded(
                symbolsLength,
                dailyLimit - symbolsAddedToday
            );
        }

        ISymmio(symmioAddress).addSymbols(symbols);
        symbolsAddedToday += symbolsLength;
    }

    /**
     * @dev Updates the daily limit for adding symbols.
     * Can only be called by accounts with the DEFAULT_ADMIN_ROLE.
     * Emits a {DailyLimitUpdated} event.
     * @param _dailyLimit The new daily limit.
     */
    function setDailyLimit(
        uint256 _dailyLimit
    ) public onlyRole(DEFAULT_ADMIN_ROLE) {
        dailyLimit = _dailyLimit;
        emit DailyLimitUpdated(_dailyLimit);
    }
}
