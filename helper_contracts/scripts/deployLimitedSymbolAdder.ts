import { ethers, run } from "hardhat";

function sleep(ms: number) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function main() {
  const contractName = "LimitedSymbolAdder";
  const factory = await ethers.getContractFactory("contractName");

  const symmio = "";
  const admin = ""; // multi-sig
  const operator = "";
  const dailyLimit = 10;
  const contract = await factory.deploy(symmio, admin, operator, dailyLimit);

  await contract.waitForDeployment();

  console.log(`${contractName} deployed: ${await contract.getAddress()}`);

  sleep(15000);
  console.log("Verifying Contract");

  await run("verify:verify", {
    address: await contract.getAddress(),
    constructorArguments: [symmio, admin, operator, dailyLimit],
  });
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
