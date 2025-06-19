// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IBurnable1155 is IERC1155 {
    function burn(address account, uint256 id, uint256 value) external;
}

contract Redemption is Ownable, ReentrancyGuard {
    IBurnable1155 public immutable nft;
    IERC20        public immutable chaos;

    mapping(uint256 => uint256) public redemptionAmount;

    event Redeemed(address indexed user, uint256 tier, uint256 amount);

    constructor(address _nft, address _chaos)
        Ownable(msg.sender)
    {
        nft   = IBurnable1155(_nft);
        chaos = IERC20(_chaos);

        redemptionAmount[1] =  5_000_000 * 1e18;   // Common
        redemptionAmount[2] = 20_000_000 * 1e18;   // Rare
        redemptionAmount[3] = 50_000_000 * 1e18;   // Epic
        redemptionAmount[4] = 120_000_000 * 1e18;  // Gold
    }

    function redeem(uint256 tier) external nonReentrant {
        require(tier >= 1 && tier <= 4, "bad tier");
        require(nft.balanceOf(msg.sender, tier) >= 1, "no NFT");

        uint256 amt = redemptionAmount[tier];
        require(chaos.balanceOf(address(this)) >= amt, "vault empty");

        nft.safeTransferFrom(msg.sender, address(this), tier, 1, "");
        nft.burn(address(this), tier, 1);

        require(chaos.transfer(msg.sender, amt), "CHAOS tx fail");
        emit Redeemed(msg.sender, tier, amt);
    }

    function topUp(uint256 amount) external onlyOwner {
        chaos.transferFrom(msg.sender, address(this), amount);
    }
}
