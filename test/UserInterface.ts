import {
  time,
  loadFixture,
} from "@nomicfoundation/hardhat-toolbox/network-helpers";
import { anyValue } from "@nomicfoundation/hardhat-chai-matchers/withArgs";
import { expect } from "chai";
import { ethers } from "hardhat";

describe("UserInterface", function () {
  // We define a fixture to reuse the same setup in every test.
  // We use loadFixture to run this setup once, snapshot that state,
  // and reset Hardhat Network to that snapshot in every test.
  async function deployUserInterface() {
    // for sepolia 0xb83E47C2bC239B3bf370bc41e1459A34b41238D0. See the
    // https://docs.chain.link/chainlink-functions/supported-networks
    let chainLinkRouter = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
    // Sub ID: 1705. Obtained at https://functions.chain.link/sepolia/new
    // To obtain the subscription id create an account on the platform.
    // Make sure to add UserInterface as the consumer.
    let chainLinkSubId = 1705;
    // For sepolia: 0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000
    let chainLinkDonId = "0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000";

    // Contracts are deployed using the first signer/account by default
    const [owner, otherAccount] = await ethers.getSigners();

    const UserInterface = await ethers.getContractFactory("UserInterface");
    const userInterface = await UserInterface.deploy(chainLinkRouter, chainLinkSubId, chainLinkDonId);

    return { userInterface, owner, otherAccount };
  }

  describe("Deployment", function () {
    it("Should set the right unlockTime", async function () {
      const { userInterface } = await loadFixture(deployUserInterface);

      let txHash = "0xa2b064f7cf92f29f4c0ac0f2085291467717128830f9b90e870fad787f6ce907";
      let targetContract = "0x3f4b6664338f23d2397c953f2ab4ce8031663f80";
      let token = "0x3f4b6664338f23d2397c953f2ab4ce8031663f80";
      let tokenId = 1;

      await userInterface.printTxHash(txHash, targetContract, token, tokenId);
    });

  });

});
