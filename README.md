## Chaos Coin Deployment Guide (Fuji Testnet)

Follow these steps to deploy the contracts to the Fuji test network using Hardhat.

### 1. Install dependencies

Make sure you have Node.js installed. Run the following command in the project
root to install the required packages:

```bash
npm install
```

### 2. Configure environment variables

Copy `.env.example` to `.env` and fill in your private key. The RPC URL for
Fuji is included for convenience:

```bash
cp .env.example .env
# Edit .env and set PRIVATE_KEY to your wallet's private key
```

### 3. Compile the contracts

```bash
npx hardhat compile
```

### 4. Deploy

To deploy the full Chaos Coin system run:

```bash
npx hardhat run contracts/scripts/deployFuji.ts --network fuji
```

This script will deploy the `ChaosToken`, `RewardsVault`, `Staking`,
`AttractorNFT` and `Redemption` contracts and wire them together.
