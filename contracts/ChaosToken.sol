// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * CHAOS utility token: sell/P2P fee, whale surcharge, fee split 65/35.
 * Uses OZ v5: override _update(), not _transfer().
 */
contract ChaosToken is ERC20, Pausable, Ownable {
    /* ---------- constants ---------- */
    uint256 public constant MAX_SUPPLY      = 100_000_000_000 * 1e18; // 100 B
    uint16  public constant BASE_SELL_BP    = 500;   // 5 %
    uint16  public constant BASE_P2P_BP     = 33;    // 0.33 %
    uint16  public constant WHALE_EXTRA_BP  = 2000;  // +20 %
    uint256 public constant WHALE_THRESHOLD = MAX_SUPPLY / 100;       // 1 %

    /* ---------- fee routing ---------- */
    address public treasurySafe;
    address public liquidityCollector;

    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public isDexPair;

    event TreasuryUpdated(address indexed newAddr);
    event LiquidityUpdated(address indexed newAddr);

    constructor(address _treasury, address _liquidity)
        ERC20("Chaos", "CHAOS")
        Ownable(msg.sender)
    {
        require(_treasury != address(0) && _liquidity != address(0), "zero addr");
        treasurySafe       = _treasury;
        liquidityCollector = _liquidity;

        _mint(msg.sender, MAX_SUPPLY);

        isFeeExempt[msg.sender]             = true;
        isFeeExempt[address(this)]          = true;
        isFeeExempt[treasurySafe]           = true;
        isFeeExempt[liquidityCollector]     = true;
        isFeeExempt[0x000000000000000000000000000000000000dEaD] = true;
    }

    /* ---------- INTERNAL HOOK ---------- */
    function _update(address from, address to, uint256 amount) internal override whenNotPaused {
        // allow mint & burn pathways to flow through
        if (from == address(0) || to == address(0)) {
            super._update(from, to, amount);
            return;
        }

        uint256 fee = 0;
        if (!isFeeExempt[from] && !isFeeExempt[to]) {
            bool isSell = isDexPair[to];
            bool isP2P  = !isSell && !isDexPair[from];

            if (isSell)      fee = (amount * BASE_SELL_BP) / 10_000;
            else if (isP2P)  fee = (amount * BASE_P2P_BP)  / 10_000;

            if (isSell && amount >= WHALE_THRESHOLD) {
                fee += (amount * WHALE_EXTRA_BP) / 10_000;
            }
        }

        if (fee > 0) {
            uint256 stakingShare   = (fee * 65) / 100;
            uint256 liquidityShare = fee - stakingShare;

            super._update(from, treasurySafe,       stakingShare);
            super._update(from, liquidityCollector, liquidityShare);

            amount -= fee;
        }

        super._update(from, to, amount);
    }

    /* ---------- admin helpers ---------- */
    function setDexPair(address pair, bool val) external onlyOwner {
        isDexPair[pair] = val;
    }

    function setFeeExempt(address acct, bool val) external onlyOwner {
        isFeeExempt[acct] = val;
    }

    function setTreasury(address newAddr) external onlyOwner {
        require(newAddr != address(0), "zero addr");
        treasurySafe = newAddr;
        emit TreasuryUpdated(newAddr);
    }

    function setLiquidity(address newAddr) external onlyOwner {
        require(newAddr != address(0), "zero addr");
        liquidityCollector = newAddr;
        emit LiquidityUpdated(newAddr);
    }

    /* ---------- pause control ---------- */
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
