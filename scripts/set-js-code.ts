import { ethers } from "hardhat";
import fs from "fs";
import path from "path";
import {task} from "hardhat/config";

type SourceType = "NFT" | "ERC20";

task("set-source", "Writes to the smartcontract the Javascript code that verifies transaction").
    addParam("address", "UserInterface address").
    addParam("jsType", "Set NFT recovery or Token recovery script").
    setAction(async (taskArgs, hre) => {
    try {
        const UserInterfaceFactory = await ethers.getContractFactory("UserInterface");
        const userInterface = UserInterfaceFactory.attach(taskArgs.address);

        const jsType: SourceType | undefined = taskArgs.jsType;
        if (jsType === undefined) {
            console.error(`jsType must be 'NFT' or 'ERC20'`);
            return;
        }

        const fileName = jsType === "NFT" ? "nft_source_to_put.txt" : "token_source_to_put.txt";

        const source = fs.readFileSync(path.resolve(__dirname, fileName)).toString();

        console.log(`Setting JS code for ${jsType} up on blockchain`);
        let tx = await userInterface.setTokenSource(source);
        await tx.wait();

        console.log(`JS Code was set successfully`);
    } catch (error) {
        console.log(error);
    }
})

