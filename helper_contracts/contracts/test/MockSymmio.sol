// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "../interfaces/ISymmio.sol";

contract MockSymmio is ISymmio {
    mapping(address => bool) public partyBEmergencyStatus;
    mapping(uint256 => Quote) public mockQuotes;
    mapping(uint256 => Symbol) public mockSymbols;

    event PartyBEmergencyStatusSet(address partyB, bool status);

    function setPartyBEmergencyStatus(
        address[] memory partyBs,
        bool status
    ) external {
        for (uint i = 0; i < partyBs.length; i++) {
            partyBEmergencyStatus[partyBs[i]] = status;
            emit PartyBEmergencyStatusSet(partyBs[i], status);
        }
    }

    function getPartyBEmergencyStatus(
        address partyB
    ) external view returns (bool) {
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
    }

    function getSymbol(uint256 symbolId) public view returns (Symbol memory) {
        return mockSymbols[symbolId];
    }

    function setSymbolTradingFee(
        uint256 symbolId,
        uint256 tradingFee
    ) external {}

    function setForceCloseGapRatio(
        uint256 symbolId,
        uint256 forceCloseGapRatio
    ) external {}

    function forceCloseGapRatio(
        uint256 symbolId
    ) external view returns (uint256) {
        return 1;
    }

    function addSymbols(Symbol[] memory symbols) external override {}
}
