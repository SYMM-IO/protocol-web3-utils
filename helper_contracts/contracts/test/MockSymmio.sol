// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/ISymmio.sol";

contract MockSymmio is ISymmio {
	mapping(address => bool) public partyBEmergencyStatus;
	mapping(uint256 => Quote) public mockQuotes;
	mapping(uint256 => Symbol) public mockSymbols;
	Symbol[] public symbols;

	event PartyBEmergencyStatusSet(address partyB, bool status);

	function setPartyBEmergencyStatus(address[] memory partyBs, bool status) external {
		for (uint i = 0; i < partyBs.length; i++) {
			partyBEmergencyStatus[partyBs[i]] = status;
			emit PartyBEmergencyStatusSet(partyBs[i], status);
		}
	}

	function getPartyBEmergencyStatus(address partyB) external view returns (bool) {
		return partyBEmergencyStatus[partyB];
	}

	function setMockQuote(uint256 quoteId, Quote memory quote) public {
		mockQuotes[quoteId] = quote;
	}

	function getQuote(uint256 quoteId) public view returns (Quote memory) {
		return mockQuotes[quoteId];
	}

	function setMockSymbol(uint256 symbolId, Symbol memory symbol) public {
		mockSymbols[symbolId] = symbol;
		symbols.push(symbol);
	}

	function getSymbol(uint256 symbolId) public view returns (Symbol memory) {
		return mockSymbols[symbolId];
	}

	function getSymbols(uint256 start, uint256 size) public view returns (Symbol[] memory) {
		uint256 end = start + size;
		if (end > symbols.length) {
			end = symbols.length;
		}
		Symbol[] memory result = new Symbol[](end - start);
		for (uint256 i = start; i < end; i++) {
			result[i - start] = symbols[i];
		}
		return result;
	}

	function setSymbolTradingFee(uint256 symbolId, uint256 tradingFee) external {}

	function setForceCloseGapRatio(uint256 symbolId, uint256 forceCloseGapRatio) external {}

	function forceCloseGapRatio(uint256 symbolId) external view returns (uint256) {
		return 1;
	}

	function addSymbols(Symbol[] memory symbols) external override {}
}
