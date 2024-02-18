import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
//import "@nomiclabs/hardhat-etherscan";
import dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  defaultNetwork: "hardhat",

  networks: {     
      sepolia: {
        url: process.env.RPC,
        //@ts-ignore
        accounts: [process.env.PRIVATE_KEY],
      },
  },
  };

export default config;