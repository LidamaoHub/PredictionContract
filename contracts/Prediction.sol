// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract PredictionContract {
    mapping(address => uint256) public sideA;
    mapping(address => uint256) public sideB;
    mapping(address => bool) public claimedList;
    enum Side {
        None,
        SideA,
        SideB
    }
    enum CoinType {
        None,
        ETH,
        COIN
    }

    bool public publishState = true;
    bool public arbitrated = false;

    uint256 public sideAShares = 0;
    uint256 public sideBShares = 0;
    uint256 public sharePrice;
    string public MetaHash;
    address payable public adminAddress;
    address payable public creator;
    uint256 public immutable fee;
    uint256 public winner = 0;
    CoinType coinType = CoinType.ETH;
    address WETH = 0xc778417E063141139Fce010982780140Aa0cD5Ab;
    IERC20 token;
    address public CoinAddress = WETH;
    uint256 public winnerShare;
    address public refundAdmin;
    uint8 public voteState = 0; //0未发布,1投票中,2仲裁中,3结束
    uint256 public maxShares = 200;
    uint256 public endTime;
string public name = "Prediction";
    //需要加一个时间限制模块
    //creator应该是chef,用来分红
    //admin应该是创建者/多签合约,用来实际控制
    constructor(
        string memory _metaHash,
        uint256 _sharePrice,
        address payable _adminAddress,
        uint256 _fee,
        uint8 _coinType,
        address _coinAddress,
        uint256 _endTime
    ) {
        require(
            _endTime > block.timestamp,
            "End Time Should Be Later Than Now"
        );
        endTime = _endTime;
        MetaHash = _metaHash;
        sharePrice = _sharePrice;
        adminAddress = _adminAddress;

        creator = payable(msg.sender);

        fee = _fee;
        if (_coinType == 1) {
            coinType = CoinType.COIN;
            CoinAddress = _coinAddress;
            token = IERC20(_coinAddress);
        }
    }

    modifier onlyAdmin() {
        require(msg.sender == adminAddress, "Only Admin");
        _;
    }

    modifier onlyOpen() {
        require(publishState, "Prediction Not Be Published");
        require(!arbitrated, "Arbitrated");
        require(block.timestamp <= endTime, "Vote Was Over");
        _;
    }

    modifier perCheckVote(uint8 side, uint256 share) {
        require(voteState == 1, "Vote Not Be Opened");
        require(!arbitrated, "Arbitrate Was Over");
        require(share > 0, "Nothing Is Free");
        // 如果投票1,则sideb必须等于0,如果投2,则sidea必须为0
        require(
            ((side == 1) && (sideB[msg.sender] == 0)) ||
                ((side == 2) && (sideA[msg.sender] == 0)),
            "Not Allowed Vote Both Side"
        );
        _;
    }

    function predictionInfo()
        external
        view
        returns (
            bool,
            uint8,
            uint256,
            uint256,
            address,
            address,
            uint256,
            uint256,
            string memory
        )
    {
        // return basic infomation of the prediction
        return (
            publishState,
            voteState,
            sideAShares,
            sideBShares,
            CoinAddress,
            adminAddress,
            sharePrice,
            fee,
            MetaHash
        );
    }

    function getUserShares(address userAddress)
        external
        view
        returns (uint8, uint256)
    {
        if (sideA[userAddress] > 0) {
            return (1, sideA[userAddress]);
        }
        if (sideB[userAddress] > 0) {
            return (2, sideB[userAddress]);
        }
        return (0, 0);
    }

    function startVoting() external onlyAdmin {
        require(voteState == 0, "Has Been Started");
        voteState = 1;
    }

    function stopVoting() external onlyAdmin {
        require(voteState == 1, "Vote Not Started");
        voteState = 2;
    }

    function changeEndTime(uint256 _endTime) external onlyAdmin {
        require(_endTime > endTime);
        endTime = _endTime;
    }

    function switchPublishState() external onlyAdmin {
        publishState = !publishState;
    }

    function voteETH(uint8 side, uint256 share)
        external
        payable
        perCheckVote(side, share)
    {
        uint256 totalAmount = sharePrice * share;
        require(msg.value >= totalAmount, "Incorrect Amount");
        _vote(side, share);
    }

    function voteERC20(uint8 side, uint256 share)
        external
        perCheckVote(side, share)
    {
        //TODO 仲裁者不可以投票
        require(msg.sender != adminAddress, "Admin Can Not Vote");
        uint256 totalAmount = sharePrice * share;
        token.transferFrom(msg.sender, address(this), totalAmount);
        _vote(side, share);
    }

    function _vote(uint8 side, uint256 share) internal {
        if (side == 1) {
            sideA[msg.sender] += share;
            sideAShares += share;
        }
        if (side == 2) {
            sideB[msg.sender] += share;
            sideBShares += share;
        }
    }

    function getBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    //仲裁应该多签,而不是单人签名
    function arbitrate(uint256 side) external onlyAdmin {
        require(voteState == 2, "Should Start Voting");
        require(!arbitrated, "Arbitrate Was Over");
        arbitrated = true;

        require(sideAShares != 0 && sideBShares != 0, "Use Refund Instand"); //如果有一个side为空,则预测不成立
        uint256 _balance = getBalance();
        //转账给admin
        uint256 feeAmount = (_balance * fee) / 100;
        token.transfer(adminAddress, feeAmount);
        if (creator != payable(0)) {
            uint256 chefAmount = (_balance * 5) / 1000;
            token.transfer(creator, chefAmount);
        }

        winner = side;
        if (side == 1) {
            winnerShare = sideAShares;
        }
        if (side == 2) {
            winnerShare = sideBShares;
        }
        voteState = 3;
    }

    function Refund() external {
        require(sideAShares == 0 || sideBShares == 0, "Use Arbitrate Instand");
        require(!(sideAShares == 0 && sideBShares == 0), "Can Not Refund");
        arbitrated = true;

        if (sideAShares == 0) {
            winner = 2;
            winnerShare = sideBShares;
        } else {
            winner = 1;
            winnerShare = sideAShares;
        }
    }

    function allShares() public view returns (uint256) {
        return sideAShares + sideBShares;
    }

// TODO 重大问题,赢家分走是否越早越多
    function claim() external {
        require(!claimedList[msg.sender], "You Have Claimed");
        require(arbitrated, "Vote Not Over");
        uint256 shareA = sideA[msg.sender];
        uint256 shareB = sideB[msg.sender];
        require(shareA != shareB, "Never Think About It");
        uint256 userSide = 1;
        uint256 balance = getBalance();
        uint256 userShares;

        if (shareB > shareA) {
            userShares = shareB;
            userSide = 2;
        } else {
            userShares = shareA;
        }
        claimedList[msg.sender] = true;

        require(userSide == winner, "You Lose");

        uint256 userAmount = (userShares * balance) / winnerShare;

        token.transfer(msg.sender, userAmount);
    }
}
