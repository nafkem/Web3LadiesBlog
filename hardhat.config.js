require("dotenv").config()
require("@nomicfoundation/hardhat-toolbox")

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.18",
  networks: {
    mumbai: {
      url: process.env.EVM_RPC,
      accounts: [process.env.PRIVATEKEY],
    },
  },
  etherscan: {
    apiKey: {
      polygonMumbai: process.env.ETHERSCAN_API_KEY,
    },
  },
}
