// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

import "./interfaces/ISymmio.sol";
import "@openzeppelin/contracts/access/AccessControlEnumerable.sol";

contract EasyBatchSetForceCloseGapRatio is AccessControlEnumerable {
    address public symmioAddress;
    bytes32 public constant SETTER_ROLE = keccak256("SETTER_ROLE");

    constructor(address _symmioAddress, address admin, address setter) {
        symmioAddress = _symmioAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, admin);
        _setupRole(SETTER_ROLE, setter);
    }

    function setForceCloseGapRatioBatch(
        uint256[] memory symbolIds,
        uint256[] memory forceCloseGapRatios
    ) external onlyRole(SETTER_ROLE) {
        require(
            symbolIds.length == forceCloseGapRatios.length,
            "Input arrays must have the same length"
        );

        for (uint256 i = 0; i < symbolIds.length; i++) {
            require(ISymmio(symmioAddress).forceCloseGapRatio(symbolIds[i]) == 0, "Only allowed to set for ones with zero ratio now");
            ISymmio(symmioAddress).setForceCloseGapRatio(
                symbolIds[i],
                forceCloseGapRatios[i]
            );
        }
    }
}