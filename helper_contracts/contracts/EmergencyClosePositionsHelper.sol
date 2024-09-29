// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./interfaces/ISymmio.sol";
import "./interfaces/ISymmioPartyB.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract EmergencyClosePositionsHelper is Ownable {
    address public symmioAddress;
    address public partyBAddress;

    constructor(
        address _symmioAddress,
        address _partyBAddress,
        address _owner
    ) Ownable() {
        symmioAddress = _symmioAddress;
        partyBAddress = _partyBAddress;
        _transferOwnership(_owner);
    }

    function emergencyClosePositions(
        bytes[] memory _callDatas
    ) external onlyOwner {
        address[] memory partyBs = new address[](1);
        partyBs[0] = partyBAddress;
        require(
            !ISymmio(symmioAddress).getPartyBEmergencyStatus(partyBAddress),
            "EmergencyClosePositionsHelper: PartyB is already in emergency status"
        );
        ISymmio(symmioAddress).setPartyBEmergencyStatus(partyBs, true);

        for (uint8 i; i < _callDatas.length; i++) {
            bytes memory _callData = _callDatas[i];
            require(
                _callData.length >= 4,
                "EmergencyClosePositionsHelper: Invalid call data"
            );
            bytes4 functionSelector;
            assembly {
                functionSelector := mload(add(_callData, 0x20))
            }
            require(
                functionSelector == 0xa3039431,
                "EmergencyClosePositionsHelper: Only emergencyClosePosition is allowed"
            );

            // Extract quoteId from callData
            uint256 quoteId;
            assembly {
                quoteId := mload(add(_callData, 0x24))  // 0x20 (length) + 0x04 (selector)
            }

            ISymmio.Quote memory quote = ISymmio(symmioAddress).getQuote(quoteId);
            ISymmio.Symbol memory symbol = ISymmio(symmioAddress).getSymbol(quote.symbolId);

            require(!symbol.isValid, "EmergencyClosePositionsHelper: Symbol should be invalid");
        }

        ISymmioPartyB(partyBAddress)._call(_callDatas);
        ISymmio(symmioAddress).setPartyBEmergencyStatus(partyBs, false);
    }
}