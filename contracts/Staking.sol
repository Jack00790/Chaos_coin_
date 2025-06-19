// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IRewardsVault {
    function transfer(address to, uint256 amt) external returns (bool);
}

contract Staking is Ownable, ReentrancyGuard {
    /* ---------- config ---------- */
    IERC20 public immutable chaos;
    IRewardsVault public immutable vault;

    uint256 public minStakeRequired = 500_000_000 * 1e18; // 500 M

    uint256 constant TWO_WEEKS = 14 days;
    uint256 constant MONTH     = 30 days;
    uint256 constant QUARTER   = 90 days;

    struct StakeInfo {
        uint256 amount;
        uint256 unlock;
        uint256 reward;
        bool    active;
    }
    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amt, uint256 unlock, uint256 reward);
    event Unstaked(address indexed user, uint256 paid);

    constructor(address _token, address _vault)
        Ownable(msg.sender)
    {
        chaos = IERC20(_token);
        vault = IRewardsVault(_vault);
    }

    /* ---------- stake / unstake ---------- */
    function stake(uint8 periodIndex, uint256 amount) external nonReentrant {
        require(amount >= minStakeRequired, "below min");
        require(!stakes[msg.sender].active, "already staked");
        require(periodIndex < 3, "bad idx");

        uint256 duration = periodIndex == 0 ? TWO_WEEKS :
                           periodIndex == 1 ? MONTH     : QUARTER;
        uint256 rate     = periodIndex == 0 ? 5  :
                           periodIndex == 1 ? 12 : 50;
        uint256 reward   = (amount * rate) / 100;

        chaos.transferFrom(msg.sender, address(this), amount);

        stakes[msg.sender] = StakeInfo({
            amount:  amount,
            unlock:  block.timestamp + duration,
            reward:  reward,
            active:  true
        });

        emit Staked(msg.sender, amount, block.timestamp + duration, reward);
    }

    function unstake() external nonReentrant {
        StakeInfo storage s = stakes[msg.sender];
        require(s.active, "no stake");
        require(block.timestamp >= s.unlock, "locked");

        s.active = false;
        chaos.transfer(msg.sender, s.amount);
        require(vault.transfer(msg.sender, s.reward), "reward fail");

        emit Unstaked(msg.sender, s.amount + s.reward);
    }

    /* ---------- admin ---------- */
    function setMinStakeRequired(uint256 newMin) external onlyOwner {
        minStakeRequired = newMin;
    }
}
