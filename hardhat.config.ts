import dotenv from "dotenv";
dotenv.config(); // call it before initializing `vars`

import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";


const INFURA_API_KEY = process.env.HARDHAT_VAR_INFURA_API_KEY as string;
const SEPOLIA_PRIVATE_KEY = process.env.HARDHAT_VAR_SEPOLIA_PRIVATE_KEY as string;

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: process.env.HARDHAT_VAR_ETHERSCAN as string,
  },
  solidity: "0.8.22",
  networks: {
    sepolia: {
      url: `https://sepolia.infura.io/v3/${INFURA_API_KEY}`,
      accounts: [SEPOLIA_PRIVATE_KEY]
    },
  },
};

export default config;
