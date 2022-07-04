require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-deploy");
require("dotenv").config();
// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: false,
        runs: 200,
      },
    },
  },
  networks: {
    rinkeby: {
      url: "https://speedy-nodes-nyc.moralis.io/0ec81e1f2f45bea5e5616aea/eth/rinkeby",
      accounts:
          process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
    matic: {
      url:"https://speedy-nodes-nyc.moralis.io/0ec81e1f2f45bea5e5616aea/polygon/mumbai",
      accounts:
          process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
    // apiKey:{
    //   polygonMumbai:  "UU5M7U91W3THX3VMU8P4M9BMZRDFHF3QQA"
    // }
  },
  gasReporter: {
    enabled: true,
    outputFile:"gas-report.txt",
    currency: "USD",
    noColors:true,
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    // token:"MATIC"
  },

};