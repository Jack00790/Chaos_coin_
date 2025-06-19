// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RewardsVault is Ownable {
    IERC20 public immutable chaos;
    address public stakingContract;
    address public redemptionContract;

    event RewardPaid(address indexed to, uint256 amount, string reason);
    event VaultFunded(address indexed from, uint256 amount);

    modifier onlyStakingOrRedemption() {
        require(msg.sender == stakingContract || msg.sender == redemptionContract, "Not authorized");
        _;
    }

    constructor(address _chaos) Ownable(msg.sender) {
        require(_chaos != address(0), "zero chaos address");
        chaos = IERC20(_chaos);
    }

    function setStakingContract(address _staking) external onlyOwner {
        require(_staking != address(0), "zero address");
        stakingContract = _staking;
    }

    function setRedemptionContract(address _redeem) external onlyOwner {
        require(_redeem != address(0), "zero address");
        redemptionContract = _redeem;
    }

    function payReward(address to, uint256 amount, string calldata reason)
        external
        onlyStakingOrRedemption
        returns (bool)
    {
        require(to != address(0), "zero address");
        require(amount > 0, "zero amount");

        bool success = chaos.transfer(to, amount);
        require(success, "CHAOS transfer failed");

        emit RewardPaid(to, amount, reason);
        return true;
    }

    function fundVault(uint256 amount) external {
        require(amount > 0, "zero amount");
        bool success = chaos.transferFrom(msg.sender, address(this), amount);
        require(success, "Vault funding failed");
        emit VaultFunded(msg.sender, amount);
    }

    function vaultBalance() external view returns (uint256) {
        return chaos.balanceOf(address(this));
    }
}
