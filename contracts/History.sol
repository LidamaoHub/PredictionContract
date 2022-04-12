// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Prediction.sol";

contract History is Ownable {
    string public name = "History";
    // 仲裁上线
    // 仲裁结束
    // 中间人列表
    enum VoteType {
        None,
        Support,
        Against
    }
    struct VoteItem {
        address voter;
        VoteType side;
    }
    //如果仲裁组跑路一人,则锁定其所有代币,所以理论上必须所有人都都通过
    //投票加一个锁定时间
    struct Prediction {
        address contractAddress;
        mapping(address => VoteType) publishVoteMap;
        VoteItem[] publishVoteList;
        mapping(address => VoteType) arbitratorVoteMap;
        VoteItem[] arbitratorVoteList;
        uint256 endBlock;
    }

    address[] _arbitratorList;
    mapping(address => bool) arbitratorList;
    uint256 _nextId = 0;
    mapping(uint256 => Prediction) public PredictionList;

    constructor(address[] memory aList) {
        for (uint256 i = 0; i < aList.length; i++) {
            arbitratorList[aList[i]] = true;
            _arbitratorList.push(aList[i]);
        }
    }

    modifier onlyArbitrator() {
        require(arbitratorList[msg.sender], "onlyArbitrator");
        _;
    }

    function CreatePrediction(
        string memory _metaHash,
        uint256 _sharePrice,
        uint256 _fee,
         uint8 _coinType,
        address coinAddress,
        uint256 _endTime
    ) external returns (uint256) {
        uint256 predictionId = NextId();
        address predictionAddress = address(
            new PredictionContract(
                _metaHash,
                _sharePrice,
                payable(msg.sender),
                _fee,
                _coinType,
                coinAddress,
                _endTime
            )
        );

        Prediction storage newPred = PredictionList[predictionId];
        newPred.contractAddress = predictionAddress;
        newPred.endBlock = block.timestamp;

        _nextId = _nextId + 1;
        return predictionId;
    }

    uint256 demoId = 0;

    function demo() public returns (uint256) {
        demoId += 1;
        return demoId;
    }

    function getArbitrator() external view returns (address[7] memory) {
        address[7] memory returnList;
        uint256 id = 0;
        for (uint256 i = 0; i < _arbitratorList.length; i++) {
            if (arbitratorList[_arbitratorList[i]]) {
                returnList[id] = _arbitratorList[i];
                id += 1;
            }
        }
        return returnList;
    }

    function setArbitrator(address userAddress, bool _type) external onlyOwner {
        arbitratorList[userAddress] = _type;
        _arbitratorList.push(userAddress);
    }

    function NextId() public view returns (uint256) {
        return _nextId + 1;
    }

    function VotePredictionPublish(uint256 predictionId, VoteType voteType)
        external
        onlyArbitrator
    {
        require(
            PredictionList[predictionId].contractAddress != address(0),
            "illegalPredictionId"
        );
        Prediction storage pred = PredictionList[predictionId];
        require(pred.publishVoteList.length < 7, "VoteWasOver");
        require(pred.publishVoteMap[msg.sender] != VoteType.None, "Voted");
        require(voteType == VoteType.None, "ShouldChooseYourSide");
        VoteItem storage vi = pred.publishVoteList.push();
        vi.voter = msg.sender;
        vi.side = voteType;

        if (pred.publishVoteList.length == 7) {
            uint256 supportAmount = 0;
            for (uint256 i = 0; i < 7; i++) {
                if (pred.publishVoteList[i].side == VoteType.Support) {
                    supportAmount += 1;
                }
            }
            if (supportAmount >= 4) {
                PredictionContract predC = PredictionContract(
                    pred.contractAddress
                );
                predC.switchPublishState();
            }
        }
    }

    function VoteResult(uint256 predictionId, VoteType voteType)
        external
        onlyArbitrator
    {
        require(
            PredictionList[predictionId].contractAddress != address(0),
            "illegalPredictionId"
        );
        Prediction storage pred = PredictionList[predictionId];
        require(pred.arbitratorVoteList.length < 7, "VoteWasOver");
        require(pred.arbitratorVoteMap[msg.sender] != VoteType.None, "Voted");
        require(voteType == VoteType.None, "ShouldChooseYourSide");
        VoteItem storage vi = pred.arbitratorVoteList.push();
        vi.voter = msg.sender;
        vi.side = voteType;

        if (pred.arbitratorVoteList.length == 7) {
            uint256 sideAAmount = 0;
            uint256 sideBAmount = 0;
            for (uint256 i = 0; i < 7; i++) {
                if (pred.arbitratorVoteList[i].side == VoteType.Support) {
                    sideAAmount += 1;
                }
                if (pred.arbitratorVoteList[i].side == VoteType.Against) {
                    sideBAmount += 1;
                }
            }
            if (sideAAmount >= 4 || sideBAmount >= 4) {
                PredictionContract predC = PredictionContract(
                    pred.contractAddress
                );
                uint256 side = 1;
                if (sideBAmount > sideAAmount) {
                    side = 2;
                }
                predC.arbitrate(side);
                //处理仲裁结果
            }
        }
    }
}
