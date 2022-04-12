
const hre = require("hardhat");

async function main() {
 
  await hre.run('compile');

  const CHEF = await hre.ethers.getContractFactory("contracts/PredictChef.sol:PredictChef");
  const chef = await CHEF.deploy();
  

  await chef.deployed();

  console.log("Deploy the predict chef to:", chef.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
