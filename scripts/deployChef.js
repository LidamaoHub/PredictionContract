
const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

async function main() {
 
  await hre.run('compile');

  let address = "0xC9a43158891282A2B1475592D5719c001986Aaec"
  const CHEF = await hre.ethers.getContractFactory("contracts/PredictChef.sol:PredictChef");
  const upgraded = await upgrades.upgradeProxy(address,CHEF);
  // const upgraded = await upgrades.deployProxy(CHEF);
  

  await upgraded.deployed();

  console.log("Deploy the predict chef to:", upgraded.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
