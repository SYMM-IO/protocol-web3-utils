// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Ownable2Step} from "@openzeppelin/contracts/access/Ownable2Step.sol";
import {SafeMath} from "@openzeppelin/contracts/utils/math/SafeMath.sol";

/**
 * @title UserPowers
 * @dev Contract for managing user powers with 18 decimal precision
 * Uses two-step ownership transfer for enhanced security
 */
contract UserPowers is Ownable2Step {
    using SafeMath for uint256;

    // Custom errors
    error ZeroAddress();
    error ArrayLengthMismatch();
    error EmptyArrays();

    // Mapping from user address to their power value (with 18 decimals precision)
    mapping(address => uint256) public userPowers;

    // Events
    event PowersSetBatch(address[] users, uint256[] powers);

    /**
     * @dev Sets powers for multiple users in a single transaction
     * @param users Array of user addresses
     * @param powers Array of power values with 18 decimals
     */
    function setPowersBatch(address[] calldata users, uint256[] calldata powers) external onlyOwner
    {
        if (users.length != powers.length) revert ArrayLengthMismatch();
        if (users.length == 0) revert EmptyArrays();

        for (uint256 i = 0; i < users.length; i++) {
            if (users[i] == address(0)) revert ZeroAddress();
            userPowers[users[i]] = powers[i];
        }

        emit PowersSetBatch(users, powers);
    }

    /**
     * @dev Gets the power for a specific user
     * @param user Address of the user
     * @return Power value with 18 decimals
     */
    function getPower(address user) external view returns (uint256) {
        return userPowers[user];
    }
}