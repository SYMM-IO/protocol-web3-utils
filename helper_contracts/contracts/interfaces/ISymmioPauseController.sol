// SPDX-License-Identifier: SYMM-Core-Business-Source-License-1.1
// This contract is licensed under the SYMM Core Business Source License 1.1
// Copyright (c) 2023 Symmetry Labs AG
// For more information, see https://docs.symm.io/legal-disclaimer/license
pragma solidity >=0.8.18;

interface ISymmioPauseController {
	function pauseGlobal() external;

    function pauseLiquidation() external;

    function pauseAccounting() external;

    function pausePartyAActions() external;

    function pausePartyBActions() external;

    function suspendedAddress(address user) external;
	
	function unsuspendedAddress(address user) external;
}
