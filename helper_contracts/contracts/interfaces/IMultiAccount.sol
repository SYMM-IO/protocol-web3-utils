// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface IMultiAccount {
    // Other function declarations already in your interface

    /**
     * @notice Executes a series of calls on behalf of the specified account.
     * @param account The address of the account to execute the calls on behalf of.
     * @param _callDatas An array of call data to execute.
     */
    function _call(address account, bytes[] calldata _callDatas) external;
}
