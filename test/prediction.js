const hre = require("hardhat");
const { expect } = require("chai");
const { wallets, admin } = require("./wallets/wallet.json");
const Decimal = require('decimal.js');
let ethers = hre.ethers;

// 创建合约常数
let hash = "hash";
let _sharePrice = ethers.utils.parseEther("1");
let fee = 10;
let coinType = 1;
let buyAmount = 1;

// init data
let contract_address;
let address;
let tokenAddr = "0xc5a5C42992dECbae36851359345FE25997F5C42d";
let pred;
let admin_wallet = {};
// 创建不同钱包对应账户
let walletList = wallets;
let address_list = walletList.map((e) => e.address);
walletList.forEach((e) => {
  e.wallet = new ethers.Wallet(e.prev, ethers.provider);
});
admin_wallet = admin;
admin_wallet.wallet = new ethers.Wallet(admin.prev, ethers.provider);
let predc1,predc2,predc3,predc4;
let predcAdmin;
let tokenContract;
let balance1,balance2,balance3;

let token1,token2,token3,token4;
//
describe("测试部署", function () {
 

  it("部署合约", async function () {
    const accounts = await hre.ethers.getSigners();
    address = accounts[0].address;
    let endTime = parseInt(Date.now() / 1000)+60*60*24*30;

    const PREDICTION = await hre.ethers.getContractFactory(
      "PredictionContract"
    );
    pred = await PREDICTION.deploy(
      hash,
      _sharePrice,
      address,
      fee,
      coinType,
      tokenAddr,
      endTime
    );
    await pred.deployed();

    contract_address = pred.address;
    let creater = await pred.creator();

    expect(creater).to.equal(address);
  });
});
describe("合约预测", function () {
  //,测试endtime,
  it("未打开开关前无法预测", async function () {
    const predc = await hre.ethers.getContractAt(
      "contracts/Prediction.sol:PredictionContract",
      contract_address
    );
    predc1 = predc.connect(walletList[0].wallet);
    predc2 = predc.connect(walletList[1].wallet);
    predc3 = predc.connect(walletList[2].wallet);
    predc4 = predc.connect(walletList[3].wallet);
    predcAdmin = predc.connect(admin_wallet.wallet);
    await expect(predc1.voteERC20(1, 1)).to.be.reverted;
  });
  it("非创建者无法打开开关", async function () {
    await expect(predc1.switchPublishState()).to.be.reverted;
  });
  it("创建者打开开关", async function () {
    let creator = await predc1.creator();
    await predcAdmin.startVoting();
  });
  it("打开开关后添加approve不足不可以创建", async function () {
    tokenContract = await hre.ethers.getContractAt(
      "contracts/ERC20.sol:LDM",
      tokenAddr
    );
    token1 = tokenContract.connect(walletList[0].wallet);
    token2 = tokenContract.connect(walletList[1].wallet);
    token3 = tokenContract.connect(walletList[2].wallet);
    await token1.approve(contract_address, ethers.utils.parseEther("1"));
    await expect(predc1.voteERC20(1, 10)).to.be.revertedWith(
      "ERC20: insufficient allowance"
    );
    await token1.claim();
    await token2.claim();
    await token3.claim();
    await token1.approve(contract_address, ethers.utils.parseEther("10000"));
    await token2.approve(contract_address, ethers.utils.parseEther("10000"));
    await token3.approve(contract_address, ethers.utils.parseEther("10000"));
  });
  it("检查用户钱包余额", async function () {
     balance1 = await token1.balanceOf(walletList[0].address);
     balance2 = await token1.balanceOf(walletList[1].address);
    expect(balance1).to.gte(ethers.utils.parseEther("0"));
    expect(balance2).to.gte(ethers.utils.parseEther("0"));
    // console.log("账户0当前余额", ethers.utils.formatEther(balance1),ethers.utils.formatEther(balance2));
  });
  it("创建vote前双方份额都为0", async function () {
    let sideAShares = await predc1.sideAShares();
    expect(sideAShares).to.equal(0);
  });

  it("创建后各个份额都正确", async function () {
    await predc1.voteERC20(1, 1);
    let sideAShares = await predc1.sideAShares();
    let sideBShares = await predc1.sideBShares();
    let all_shares = await predc1.allShares();
    expect(all_shares).to.equal(1);
    expect(sideAShares).to.equal(1);
    expect(sideBShares).to.equal(0);
    await predc3.voteERC20(1, 1);
    await predc2.voteERC20(2, 1);
    sideAShares = await predc1.sideAShares();
    sideBShares = await predc1.sideBShares();
    all_shares = await predc1.allShares();
    expect(all_shares).to.equal(3);
    expect(sideAShares).to.equal(2);
    expect(sideBShares).to.equal(1);
  });
  it("不可两边下注", async function () {
    await expect( predc1.voteERC20(2, 1)).to.be.revertedWith('Not Allowed Vote Both Side');
    await expect( predc2.voteERC20(1, 1)).to.be.revertedWith('Not Allowed Vote Both Side');
  });

  it("可单边增注", async function () {
    await predc1.voteERC20(1, 1)
    sideAShares = await predc1.sideAShares();
    all_shares = await predc1.allShares();
    expect(all_shares).to.equal(4);
    expect(sideAShares).to.equal(3);
    balance1 = await token1.balanceOf(walletList[0].address);
  });
  it("未开奖之前不可Claim", async function () {
    await expect( predc1.claim()).to.be.revertedWith('Vote Not Over');

  });
  it("结束投票", async function () {
    await predcAdmin.stopVoting();


  });
  
});
describe("合约结算", function () {
  it("测试开奖", async function () {
    await predcAdmin.arbitrate(1)

  });

  it("测试重复开奖", async function () {
    await expect( predcAdmin.arbitrate(1)).to.be.revertedWith('Should Start Voting');

  });
  
  it("开奖后无法新投票", async function () {
    await expect( predc2.voteERC20(1, 1)).to.be.revertedWith('Vote Not Be Opened');
  });
  it("防止未参加用户Claim", async function () {
    await expect( predc4.claim()).to.be.revertedWith('Never Think About It');
    
  });
  it("失败用户claim", async function () {
    await expect( predc2.claim()).to.be.revertedWith('You Lose');
    
  });
  it("胜利用户claim", async function () {
    await predc1.claim() 
    
  });
  it("防止胜利用户重复claim", async function () {
    await expect(predc1.claim()).to.be.revertedWith('You Have Claimed'); 
    
  });
  it("胜利用户获得报酬", async function () {
    let balance1_over = await token1.balanceOf(walletList[0].address);
    // 总共注22,项目方分走2.2,用户占比阵营20%,则分成为3.96
    let diff = Decimal.sub(ethers.utils.formatEther(balance1_over),ethers.utils.formatEther(balance1))
console.log("新增",diff,"应为",3.3)
  });
  //除不开处理
  // 如果只有单方投票,则结束不抽成
  //没人投票无法结束
  //不能给
});
