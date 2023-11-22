import { ethers } from "hardhat";

async function main() {
    // address _router, uint64 _subId, bytes32 _donId, string memory _url) FunctionsClient(_router) {
    // for sepolia . See the
    // https://docs.chain.link/chainlink-functions/supported-networks
    let router = "0xb83E47C2bC239B3bf370bc41e1459A34b41238D0";
    // Sub ID: 1705. Obtained at https://functions.chain.link/sepolia/new
    // To obtain the subscription id create an account on the platform.
    // Make sure to add UserInterface as the consumer.
    let subId = 1705;
    // For sepolia:
    let donId = "0x66756e2d657468657265756d2d7365706f6c69612d3100000000000000000000";

    const userInterface = await ethers.deployContract("UserInterface", [router, subId, donId], {});

    await userInterface.waitForDeployment();

    console.log(
      `User interface was deployed to ${userInterface.target}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
