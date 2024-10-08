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
	bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");
	bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
	bytes32 public constant UNPAUSER_ROLE = keccak256("UNPAUSER_ROLE");

	// Mapping to store keccak256 hashes of symbol properties
	mapping(bytes32 => bool) public addedSymbolHashes;
	bytes32[] public symbolHashes;

	// Define custom errors
	error DailyLimitExceeded(uint256 attempted, uint256 remaining);
	error InvalidSymbolsList();
	error DuplicateSymbol(string name);

	// Define events
	event DailyLimitUpdated(uint256 newDailyLimit);
	event SymbolsAdded(uint256 count);
	event SymbolHashesCleared(address account);
	event SymmioSymbolsLoaded(uint256 start, uint256 size);

	/**
	 * @dev Initializes the contract by setting the Symmio address, admin, operator, and daily limit.
	 * @param _symmioAddress The address of the Symmio contract.
	 * @param admin The address of the contract administrator.
	 * @param operator The address of the operator.
	 * @param _dailyLimit The maximum number of symbols that can be added per day.
	 */
	constructor(address _symmioAddress, address admin, address setter, address operator, uint256 _dailyLimit) {
		symmioAddress = _symmioAddress;
		lastResetTimestamp = block.timestamp;

		// Set up roles
		_setupRole(DEFAULT_ADMIN_ROLE, admin);
		_setupRole(OPERATOR_ROLE, operator);
		_setupRole(SETTER_ROLE, setter);
		_setupRole(PAUSER_ROLE, admin);
		_setupRole(UNPAUSER_ROLE, admin);

		dailyLimit = _dailyLimit;
		emit DailyLimitUpdated(_dailyLimit);
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
	function addSymbols(ISymmio.Symbol[] memory symbols) external whenNotPaused onlyRole(OPERATOR_ROLE) {
		// Reset the counter if a new day has started
		if (block.timestamp >= lastResetTimestamp + 1 days) {
			symbolsAddedToday = 0;
			lastResetTimestamp = block.timestamp;
		}

		uint256 symbolsLength = symbols.length;

		if (symbolsLength == 0) revert InvalidSymbolsList();

		if (symbolsAddedToday + symbolsLength > dailyLimit) revert DailyLimitExceeded(symbolsLength, dailyLimit - symbolsAddedToday);

		for (uint256 i = 0; i < symbolsLength; ) {
			ISymmio.Symbol memory symbol = symbols[i];
			bytes32 symbolHash = computeSymbolHash(symbol);
			if (addedSymbolHashes[symbolHash]) revert DuplicateSymbol(symbol.name);
			addedSymbolHashes[symbolHash] = true;
			symbolHashes.push(symbolHash);
			unchecked {
				++i;
			}
		}

		ISymmio(symmioAddress).addSymbols(symbols);
		symbolsAddedToday += symbolsLength;
		emit SymbolsAdded(symbolsLength);
	}

	/**
	 * @dev Computes the keccak256 hash of a symbol's properties.
	 * @param symbol The symbol whose hash is to be computed.
	 * @return The keccak256 hash of the symbol's properties.
	 */
	function computeSymbolHash(ISymmio.Symbol memory symbol) internal pure returns (bytes32) {
		return
			keccak256(
				abi.encodePacked(
					symbol.symbolId,
					symbol.name,
					symbol.minAcceptableQuoteValue,
					symbol.minAcceptablePortionLF,
					symbol.tradingFee,
					symbol.maxLeverage,
					symbol.fundingRateEpochDuration,
					symbol.fundingRateWindowTime
				)
			);
	}

	/**
	 * @dev Clears the stored symbol hashes.
	 * Can only be called by accounts with the SETTER_ROLE.
	 */
	function clearSymbolHashes() external onlyRole(SETTER_ROLE) {
		for (uint256 i = 0; i < symbolHashes.length; i++) {
			delete addedSymbolHashes[symbolHashes[i]];
		}
		delete symbolHashes;
		emit SymbolHashesCleared(msg.sender);
	}

	/**
	 * @dev Loads symbols from the Symmio contract and stores their hashes.
	 * Can only be called by accounts with the SETTER_ROLE.
	 * @param start The starting index for fetching symbols.
	 * @param size The number of symbols to fetch.
	 */
	function loadSymmioSymbols(uint256 start, uint256 size) external onlyRole(SETTER_ROLE) {
		ISymmio.Symbol[] memory symbols = ISymmio(symmioAddress).getSymbols(start, size);
		for (uint256 i = 0; i < symbols.length; i++) {
			bytes32 symbolHash = computeSymbolHash(symbols[i]);
			if (!addedSymbolHashes[symbolHash]) {
				addedSymbolHashes[symbolHash] = true;
				symbolHashes.push(symbolHash);
			}
		}
		emit SymmioSymbolsLoaded(start, size);
	}

	/**
	 * @dev Updates the daily limit for adding symbols.
	 * Can only be called by accounts with the SETTER_ROLE.
	 * Emits a {DailyLimitUpdated} event.
	 * @param _dailyLimit The new daily limit.
	 */
	function setDailyLimit(uint256 _dailyLimit) public onlyRole(SETTER_ROLE) {
		dailyLimit = _dailyLimit;
		emit DailyLimitUpdated(_dailyLimit);
	}
}
