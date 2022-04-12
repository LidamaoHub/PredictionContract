// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Prediction.sol";

contract History is Ownable {
    string public name = "PredictChef";
    // 仲裁上线
    // 仲裁结束
    // 中间人列表

    uint256 _nextId = 0;
    mapping(uint256 => address) public PredictionList;

    constructor() {}

    // 简易版:个人签名,直接上列表
    function CreatePrediction(
        string memory _metaHash,
        uint256 _sharePrice,
        uint256 _fee,
        uint8 _coinType,
        address coinAddress,
        uint256 _endTime
    ) external  {
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

        PredictionList[predictionId] = predictionAddress;
        _nextId = _nextId + 1;
    }

    function NextId() public view returns (uint256) {
        return _nextId + 1;
    }

}
