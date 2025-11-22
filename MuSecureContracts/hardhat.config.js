require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("dotenv".config());

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.19",
    settings: {
      optimizer: {
        enabled: true,
    }
   }
  },

  networks: {
    "base-sepolia": {
      url: process.env.BASE_SEPOLIA_RPC_URL || "https://sepolia.base.org",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      gasPrice: 1000000000, // 1 gwei
      
    },
    
    "localhost": {
      url: "http//127.0.0.1:8545"
    }
  },

  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY ? {
      "base-sepolia": process.env.ETHERSCAN_API_KEY,
    } : undefined,
    customChains: [
      {
        network: "base-sepolia", 
        chainId: 84532,
        urls: {
          apiURL: "https://api-sepolia.basescan.org/api",
          browserURL: "https://sepolia.basescan.org"
        }
      }
    ]
  }
};