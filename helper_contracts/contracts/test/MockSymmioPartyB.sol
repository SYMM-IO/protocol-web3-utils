// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

contract MockPartyB {
    event CallExecuted();

    function _call(bytes[] calldata _callDatas) external {
        emit CallExecuted();
    }
}
