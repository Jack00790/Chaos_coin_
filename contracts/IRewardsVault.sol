// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IRewardsVault {
    function payReward(address to, uint256 amt, string calldata reason) external returns (bool);
}

