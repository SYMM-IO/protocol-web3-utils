// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockSymmio {
    mapping(address => bool) public partyBEmergencyStatus;

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
}
