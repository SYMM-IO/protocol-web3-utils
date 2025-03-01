// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity ^0.8.19;

import "./interfaces/ISymmio.sol";

contract NextQuoteIDVerifier {
    ISymmio public symmioFacet;

    /**
     * @notice Sets the address of the symmio contract.
     * @param _symmioAddress The address of the deployed ViewFacet.
     */
    constructor(address _symmioAddress) {
        symmioFacet = ISymmio(_symmioAddress);
    }

    /**
     * @notice Verifies if the given quote ID is the next generated quote ID.
     * @param quoteId The quote ID to verify.
     * @return True if the provided ID matches the last generated quote ID, false otherwise.
     */
    function verifyNextQuoteId(uint256 quoteId) external view returns (bool) {
        uint256 lastQuoteId = symmioFacet.getNextQuoteId();
        return quoteId == lastQuoteId;
    }
}