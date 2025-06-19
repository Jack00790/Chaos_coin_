// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract AttractorNFT is ERC1155, Ownable, Pausable {
    string public name   = "Attractor NFT";
    string public symbol = "ATTR";

    uint256 public constant TIER1 = 1;
    uint256 public constant TIER2 = 2;
    uint256 public constant TIER3 = 3;
    uint256 public constant TIER4 = 4;

    uint256 public constant TOTAL_CAP = 6_000;
    uint256 public totalSupply;
    bool    public metadataFrozen;

    mapping(uint256 => uint256) public maxSupplyPerTier;
    mapping(uint256 => uint256) public totalMintedPerTier;

    event Minted(address indexed to, uint256 tier, uint256 amount);
    event MetadataFrozen();

    constructor(string memory baseURI)
        ERC1155(baseURI)
        Ownable(msg.sender)
    {
        maxSupplyPerTier[TIER1] = 5_700;
        maxSupplyPerTier[TIER2] =   270;
        maxSupplyPerTier[TIER3] =    24;
        maxSupplyPerTier[TIER4] =     6;
    }

    /* ---------- mint / burn ---------- */
    function mint(address to, uint256 tier, uint256 amount)
        external
        onlyOwner
        whenNotPaused
    {
        require(tier >= 1 && tier <= 4, "bad tier");
        require(totalMintedPerTier[tier] + amount <= maxSupplyPerTier[tier], "tier cap");
        require(totalSupply + amount <= TOTAL_CAP, "global cap");

        totalMintedPerTier[tier] += amount;
        totalSupply              += amount;

        _mint(to, tier, amount, "");
        emit Minted(to, tier, amount);
    }

    function burn(address from, uint256 id, uint256 value) external {
        require(from == _msgSender() || isApprovedForAll(from, _msgSender()), "not owner/approved");
        _burn(from, id, value);
        totalSupply -= value;
    }

    /* ---------- metadata controls ---------- */
    function freezeMetadata() external onlyOwner {
        metadataFrozen = true;
        emit MetadataFrozen();
    }

    function setURI(string memory newuri) external onlyOwner {
        require(!metadataFrozen, "frozen");
        _setURI(newuri);
    }

    /* ---------- pause ---------- */
    function pause() external onlyOwner { _pause(); }
    function unpause() external onlyOwner { _unpause(); }
}
