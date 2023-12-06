import "dotenv/config";

import { HardhatUserConfig, vars } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "hardhat-abi-exporter";
import "./scripts/set-js-code";

// const INFURA_API_KEY = process.env.HARDHAT_VAR_INFURA_API_KEY as string;
const SEPOLIA_RPC = process.env.HARDHAT_VAR_SEPOLIA_RPC as string;
// const SEPOLIA_RPC = `https://sepolia.infura.io/v3/${INFURA_API_KEY}`;
const SEPOLIA_PRIVATE_KEY = process.env.HARDHAT_VAR_SEPOLIA_PRIVATE_KEY as string;

const config: HardhatUserConfig = {
  etherscan: {
    apiKey: process.env.HARDHAT_VAR_ETHERSCAN as string,
  },
  abiExporter: {
    path: "./user-interface/src/utils/abi",
    clear: true,
    format: "json",
    flat: true,
  },
  solidity: "0.8.22",
  networks: {
    sepolia: {
      url: SEPOLIA_RPC,
      accounts: [SEPOLIA_PRIVATE_KEY]
    },
  },
};

export default config;
