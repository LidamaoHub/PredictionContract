// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract LDM is ERC20 {
    address private _owner;
    constructor() ERC20("Lidamao", "LDM") {
         _mint(msg.sender, 100000 ether);
    }
    function claim() external {
        _mint(msg.sender,100 ether);
    }
}
