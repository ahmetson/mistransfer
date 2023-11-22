import { ethers } from "hardhat";

async function main() {
    const helloWorld = await ethers.deployContract("HelloWorld", [], {});

    await helloWorld.waitForDeployment();

    console.log(
      `HelloWorld was deployed to ${helloWorld.target}`
    );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
