// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface ISymmio {
    function setPartyBEmergencyStatus(
        address[] memory partyBs,
        bool status
    ) external;

    function getPartyBEmergencyStatus(
        address partyB
    ) external view returns (bool isEmergency);

    function setSymbolTradingFee(uint256 symbolId, uint256 tradingFee) external;

    function setForceCloseGapRatio(
        uint256 symbolId,
        uint256 forceCloseGapRatio
    ) external;

    function forceCloseGapRatio(uint256 symbolId) external view returns (uint256);

    struct Symbol {
        uint256 symbolId;
        string name;
        bool isValid;
        uint256 minAcceptableQuoteValue;
        uint256 minAcceptablePortionLF;
        uint256 tradingFee;
        uint256 maxLeverage;
        uint256 fundingRateEpochDuration;
        uint256 fundingRateWindowTime;
    }

    function getSymbol(uint256 symbolId) external view returns (Symbol memory);

    enum PositionType {
        LONG,
        SHORT
    }

    enum OrderType {
        LIMIT,
        MARKET
    }

    enum QuoteStatus {
        PENDING, //0
        LOCKED, //1
        CANCEL_PENDING, //2
        CANCELED, //3
        OPENED, //4
        CLOSE_PENDING, //5
        CANCEL_CLOSE_PENDING, //6
        CLOSED, //7
        LIQUIDATED, //8
        EXPIRED, //9
        LIQUIDATED_PENDING //10
    }

    struct LockedValues {
        uint256 cva;
        uint256 lf;
        uint256 partyAmm;
        uint256 partyBmm;
    }

    struct Quote {
        uint256 id;
        address[] partyBsWhiteList;
        uint256 symbolId;
        PositionType positionType;
        OrderType orderType;
        // Price of quote which PartyB opened in 18 decimals
        uint256 openedPrice;
        uint256 initialOpenedPrice;
        // Price of quote which PartyA requested in 18 decimals
        uint256 requestedOpenPrice;
        uint256 marketPrice;
        // Quantity of quote which PartyA requested in 18 decimals
        uint256 quantity;
        // Quantity of quote which PartyB has closed until now in 18 decimals
        uint256 closedAmount;
        LockedValues initialLockedValues;
        LockedValues lockedValues;
        uint256 maxFundingRate;
        address partyA;
        address partyB;
        QuoteStatus quoteStatus;
        uint256 avgClosedPrice;
        uint256 requestedClosePrice;
        uint256 quantityToClose;
        // handle partially open position
        uint256 parentId;
        uint256 createTimestamp;
        uint256 statusModifyTimestamp;
        uint256 lastFundingPaymentTimestamp;
        uint256 deadline;
        uint256 tradingFee;
    }

    function getQuote(uint256 quoteId) external view returns (Quote memory);
}
