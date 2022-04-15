// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Prediction.sol";

contract PredictChef is Ownable {
    string public name = "PredictChef";
    // 仲裁上线
    // 仲裁结束
    // 中间人列表

    uint256 public PredictId = 0;
    mapping(uint256 => address) public PredictionList;

    constructor() {}

    event Created(
        address indexed addr,
        uint256 indexed predId,
        address predAddress
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
        PredictionList[PredictId] = predictionAddress;
        PredictId = PredictId + 1;
        emit Created(msg.sender, predictionId, predictionAddress);
    }
}
