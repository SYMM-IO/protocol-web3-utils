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
}
