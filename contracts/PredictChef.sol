// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./Prediction.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract PredictChef {
    // 仲裁上线
    // 仲裁结束
    // 中间人列表

    uint256 public PredictId ;
    mapping(uint256 => Prediction) public PredictionList;
    address public manager;


    function initialize()  public {
        manager = msg.sender;
        PredictId = 0;
     }
   

    struct Prediction {
        bool show;
        address addr;
    }
    modifier onlyOwner() {
        require(address(msg.sender) == manager, "Only Owner");
        _;
    }
    event Created(
        address indexed addr,
        uint256 indexed predId,
        address predAddress
    );
    event SwitchShowType(
        uint256 indexed predId,
        address predAddress,
        bool showType
    );

    // 简易版:个人签名,直接上列表
    function CreatePrediction(
        string memory _metaHash,
        uint256 _sharePrice,
        uint256 _fee,
        uint8 _coinType,
        address coinAddress,
        uint256 _endTime
    ) external {
        require(_sharePrice > 0, "SharePrice>0");
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
        uint256 predictionId = PredictId;
        Prediction memory pred = Prediction(true, predictionAddress);
        PredictionList[PredictId] = pred;
        PredictId = PredictId + 1;
        emit Created(msg.sender, predictionId, predictionAddress);
    }

    function setShowType(uint256 _predictId, bool _type) external onlyOwner {
        require(PredictionList[_predictId].addr != address(0), "not in list");
        PredictionList[_predictId].show = _type;
        emit SwitchShowType(_predictId,PredictionList[_predictId].addr,_type);
    }

    function getPredict(uint256 _predictId) public view  returns (address )  {
        require(PredictionList[_predictId].addr != address(0), "not in list");
        if(PredictionList[_predictId].show){
            return PredictionList[_predictId].addr;
        }else{
            return address(0);
        }
    }

    function withdraw(address tokenAddress) external onlyOwner{
        IERC20 token = IERC20(tokenAddress);
        uint256 balance = token.balanceOf(address(this));
        token.transfer(manager, balance);
    }
}
