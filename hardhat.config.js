require("hardhat-deploy");
require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

module.exports = {
  networks: {
    mumbai: {
      url: "https://polygon-mumbai.g.alchemy.com/v2/aNkhFtivSO_X7EI3OVGoGCMwRWm46lux",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 80001,
      saveDeployments: true,
    },
    fuji: {
      url: "https://avalanche-fuji-c-chain.publicnode.com",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 43113,
      saveDeployments: true,
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: "K36W2U2EFWKS8UDJUK764QVT4WN2XIDF1Q",
      fuji: "UCUJXU5I4W4XUQ57W5S18AHEQ3XU14GPRR",
    },
  },
  namedAccounts: {
    deployer: {
      default: 0,
    },
  },
  solidity: {
    compilers: [
      {
        version: "0.8.0",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
      {
        version: "0.8.4",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
      {
        version: "0.8.15",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
      {
        version: "0.8.19",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          viaIR: true,
        },
      },
    ],
  },
};
