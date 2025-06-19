import { ethers } from "hardhat";

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying with wallet:", deployer.address);

  const ChaosToken = await ethers.getContractFactory("ChaosToken");
  const chaos = await ChaosToken.deploy(deployer.address, deployer.address);
  await chaos.deployed();
  console.log("ChaosToken deployed at:", chaos.address);

  const RewardsVault = await ethers.getContractFactory("RewardsVault");
  const vault = await RewardsVault.deploy(chaos.address);
  await vault.deployed();
  console.log("RewardsVault deployed at:", vault.address);

  const Staking = await ethers.getContractFactory("Staking");
  const staking = await Staking.deploy(chaos.address, vault.address);
  await staking.deployed();
  console.log("Staking deployed at:", staking.address);

  const AttractorNFT = await ethers.getContractFactory("AttractorNFT");
  const nft = await AttractorNFT.deploy("ipfs://QmChaosSoapBar/tier{id}.json");
  await nft.deployed();
  console.log("AttractorNFT deployed at:", nft.address);

  const Redemption = await ethers.getContractFactory("Redemption");
  const redemption = await Redemption.deploy(nft.address, chaos.address, vault.address);
  await redemption.deployed();
  console.log("Redemption deployed at:", redemption.address);

  await vault.setStakingContract(staking.address);
  await vault.setRedemptionContract(redemption.address);
  console.log("Vault wired to Staking & Redemption");

  await chaos.setTreasury(vault.address);
  console.log("Treasury set to vault");

  const fundAmount = ethers.utils.parseUnits("1000000", 18);
  await chaos.approve(vault.address, fundAmount);
  await vault.fundVault(fundAmount);
  console.log("Vault funded with:", fundAmount.toString(), "CHAOS");

  console.log("\n✅ CHAOS COIN SYSTEM DEPLOYED ✅");
  console.log("Token:", chaos.address);
  console.log("Vault:", vault.address);
  console.log("Staking:", staking.address);
  console.log("NFT:", nft.address);
  console.log("Redemption:", redemption.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
