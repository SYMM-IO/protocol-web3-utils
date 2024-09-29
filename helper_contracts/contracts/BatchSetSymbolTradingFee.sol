// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./interfaces/ISymmio.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract BatchSetSymbolTradingFee is Ownable {
    address public symmioAddress;

    constructor(address _symmioAddress, address admin) Ownable() {
        symmioAddress = _symmioAddress;
        _transferOwnership(admin);
    }

    function setSymbolTradingFeeBatch(
        uint256[] memory symbolIds,
        uint256[] memory tradingFees
    ) external onlyOwner {
        require(
            symbolIds.length == tradingFees.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < symbolIds.length; i++) {
            ISymmio(symmioAddress).setSymbolTradingFee(
                symbolIds[i],
                tradingFees[i]
            );
        }
    }
}
