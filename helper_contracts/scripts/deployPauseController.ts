import { ethers, upgrades } from "hardhat";

function sleep(ms: number) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
	const contractName = "PauseController";
	const PauseController = await ethers.getContractFactory(contractName);

    const symmioAddress = "0x91Cf2D8Ed503EC52768999aA6D8DBeA6e52dbe43";

    const globalPauser = "0x9bc9ca7e6a8f013f40617c4585508a988db7c1c7";
    const liquidationPauser = "0x9bc9ca7e6a8f013f40617c4585508a988db7c1c7";
    const accountingPauser = "0x9bc9ca7e6a8f013f40617c4585508a988db7c1c7";
    const partyAPauser = "0x9bc9ca7e6a8f013f40617c4585508a988db7c1c7";
    const partyBPauser = "0x9bc9ca7e6a8f013f40617c4585508a988db7c1c7";
    const suspender = "0x9bc9ca7e6a8f013f40617c4585508a988db7c1c7";

	const PauseControllerProxy = await upgrades.deployProxy(
        PauseController,
        [
          symmioAddress,
          globalPauser,
          liquidationPauser,
          accountingPauser,
          partyAPauser,
          partyBPauser,
          suspender
        ],
        {
          initializer: "initialize"
        }
      );
      await PauseControllerProxy.waitForDeployment();

	console.log(`${contractName} proxy deployed: ${await PauseControllerProxy.getAddress()}`);

	console.log("Sleeping before verify...");
	await sleep(25000);
	console.log("Verifying Contract now");

	// await run("verify:verify", {
	// 	address: await PauseControllerProxy.getAddress(),
	// 	constructorArguments: [],
	// });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
	console.error(error);
	process.exitCode = 1;
});
