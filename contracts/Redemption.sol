// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBurnable1155 is IERC1155 {
    function burn(address account, uint256 id, uint256 value) external;
}

interface IRewardsVault {
    function payReward(address to, uint256 amt, string calldata reason) external returns (bool);
}

contract Redemption is Ownable, ReentrancyGuard {
    IBurnable1155 public immutable nft;
    IERC20        public immutable chaos;
    IRewardsVault public immutable vault;

    mapping(uint256 => uint256) public redemptionAmount;

    event Redeemed(address indexed user, uint256 tier, uint256 amount);

    constructor(address _nft, address _chaos, address _vault)
        Ownable(msg.sender)
    {
        nft   = IBurnable1155(_nft);
        chaos = IERC20(_chaos);
        vault = IRewardsVault(_vault);

        redemptionAmount[1] =  5_000_000 * 1e18;
        redemptionAmount[2] = 20_000_000 * 1e18;
        redemptionAmount[3] = 50_000_000 * 1e18;
        redemptionAmount[4] = 120_000_000 * 1e18;
    }

    function redeem(uint256 tier) external nonReentrant {
        require(tier >= 1 && tier <= 4, "bad tier");
        require(nft.balanceOf(msg.sender, tier) >= 1, "no NFT");

        uint256 amt = redemptionAmount[tier];

        nft.safeTransferFrom(msg.sender, address(this), tier, 1, "");
        nft.burn(address(this), tier, 1);

        require(vault.payReward(msg.sender, amt, string(abi.encodePacked("Redeem: Tier ", toString(tier)))), "vault tx fail");

        emit Redeemed(msg.sender, tier, amt);
    }

    function setRedemptionAmount(uint256 tier, uint256 amt) external onlyOwner {
        redemptionAmount[tier] = amt;
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) return "0";
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
