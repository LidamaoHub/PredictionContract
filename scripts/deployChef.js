
const hre = require("hardhat");

async function main() {
 
  await hre.run('compile');

  const LDM = await hre.ethers.getContractFactory("contracts/ERC20.sol:LDM");
  const ldm = await LDM.deploy();
  

  await ldm.deployed();

  console.log("The test coin LDM deployed to:", ldm.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
