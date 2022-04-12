const hre = require("hardhat");
let rinkeby = {
    admin:"0x033cbC62238F7495E557e3591125ad6c7A0729D3",
    token:"0x788C4103b063d330D4Bde56b52C54E0e58dc6c86"
}
let local = {
    admin:"0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266",
    token:"0xB7f8BC63BbcaD18155201308C8f3540b07f84F5e"
}
let env_info = local
async function main() {
  // hash为已上传ipfs基础信息的hash
  let hash = "QmUwznjnq9PHDnCyZH1SrRV99JJAkV3TgWBuHtmKMmRg2v";
  let _sharePrice = hre.ethers.utils.parseEther("1");
  let fee = 10;
  let coinType = 1;
  let endTime = parseInt(Date.now() / 1000)+60*60*24*30;
  console.log(endTime)
  let address_admin = env_info.admin;
  await hre.run("compile");

  //此处token地址可以使用script文件夹下deployERC20完成部署,只是测试币
  let token_address = env_info.token;

  // We get the contract to deploy
  const PREDICTION = await hre.ethers.getContractFactory("PredictionContract");
  pred = await PREDICTION.deploy(
    hash,
    _sharePrice,
    address_admin,
    fee,
    coinType,
    token_address,
    endTime
  );
  await pred.deployed();

  console.log("Predict deployed to:", pred.address);
  let info = await pred.voteState()
  console.log('info',info)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
