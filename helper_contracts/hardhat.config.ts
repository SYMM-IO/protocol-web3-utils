import "@nomicfoundation/hardhat-toolbox";
import "@nomicfoundation/hardhat-verify";
import "@typechain/hardhat";
import * as dotenv from "dotenv";
import "hardhat-gas-reporter";
import { HardhatUserConfig } from "hardhat/config";
import "solidity-coverage";

dotenv.config();

const accounts_list: any = [process.env.ACCOUNT];

const bnbApiKey: string = process.env.BNB_API_KEY || "";
const blastApiKey: string = process.env.BLAST_API_KEY || "";
const baseApiKey: string = process.env.BASE_API_KEY || "";
const polygonApiKey: string = process.env.POLYGON_API_KEY || "";
const arbitrumApiKey: string = process.env.ARBITRUM_API_KEY || "";
const mantleAPIKey: string = process.env.MANTLE_API_KEY || "";

export const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  gasReporter: {
    currency: "USD",
    enabled: true,
    excludeContracts: [],
    src: "./contracts",
  },
  solidity: {
    version: "0.8.19",
    settings: {
      metadata: {
        // Not including the metadata hash
        // https://github.com/paulrberg/hardhat-template/issues/31
        bytecodeHash: "none",
      },
      // Disable the optimizer when debugging
      // https://hardhat.org/hardhat-network/#solidity-optimizer-support
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    fantom: {
      url: "https://rpcapi.fantom.network",
      accounts: accounts_list,
    },
    base: {
      url: "https://1rpc.io/base",
      accounts: accounts_list,
    },
    bnb: {
      url: "https://1rpc.io/bnb",
      accounts: accounts_list,
    },
    blast: {
      url: "https://rpc.blast.io",
      accounts: accounts_list,
    },
    polygon: {
      url: "https://polygon-rpc.com",
      accounts: accounts_list,
    },
    mantle: {
      url: "https://rpc.ankr.com/mantle",
      accounts: accounts_list,
    },
  },
  etherscan: {
    apiKey: {
      mantle: mantleAPIKey,
      base: baseApiKey,
      blast: blastApiKey,
      bnb: bnbApiKey,
      polygon: polygonApiKey,
      arbitrum: arbitrumApiKey,
    },
    customChains: [
      {
        network: "mantle",
        chainId: 5000,
        urls: {
          apiURL: "https://explorer.mantle.xyz/api",
          browserURL: "https://explorer.mantle.xyz",
        },
      },
      {
        network: "base",
        chainId: 8453,
        urls: {
          apiURL: `https://api.basescan.org/api?apiKey=${baseApiKey}`,
          browserURL: "https://basescan.org",
        },
      },
      {
        network: "blast",
        chainId: 81457,
        urls: {
          apiURL: `https://api.blastscan.io/api?apiKey=${blastApiKey}`,
          browserURL: "https://blastscan.io",
        },
      },
    ],
  },
  paths: {
    artifacts: "./artifacts",
    cache: "./cache",
    sources: "./contracts",
    tests: "./test",
  },
};

export default config;
