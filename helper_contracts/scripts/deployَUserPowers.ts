import { ethers, run } from "hardhat";

function sleep(ms: number) {
	return new Promise(resolve => setTimeout(resolve, ms));
}

async function main() {
	const contractName = "UserPowers";
	const factory = await ethers.getContractFactory(contractName);

	const contract = await factory.deploy();

	await contract.waitForDeployment();

	console.log(`${contractName} deployed: ${await contract.getAddress()}`);

	console.log("Sleeping before verify...");
	await sleep(15000);
	console.log("Verifying Contract now");

	await run("verify:verify", {
		address: await contract.getAddress(),
		constructorArguments: [],
	});
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch(error => {
	console.error(error);
	process.exitCode = 1;
});
