
const hre = require("hardhat");
const { ethers, upgrades } = require("hardhat");

async function main() {
 
  await hre.run('compile');

  // hardhat 0xC9a43158891282A2B1475592D5719c001986Aaec
  // polygon 0xddC192921Affaf7d552b75Fd5D8f2E5a1b015eAD
  //hoo 0x7edEcbd201c8AE2440D280f68E306c985b58FEDB
  //ropsten 0x61233cc075b94f4808D05BFf1b3984764b2086ba
  let address = "0xC9a43158891282A2B1475592D5719c001986Aaec"
  const CHEF = await hre.ethers.getContractFactory("contracts/PredictChef.sol:PredictChef");
  // const upgraded = await upgrades.upgradeProxy(address,CHEF);
  const upgraded = await upgrades.deployProxy(CHEF);
  

  await upgraded.deployed();

  console.log("Deploy the predict chef to:", upgraded.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
