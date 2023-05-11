//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDT is ERC20 {
    uint8 decimal;

    constructor(uint256 initialSupply, uint8 _decimal, string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, initialSupply * 10 ** _decimal);
        decimal = _decimal;
    }

    function decimals() public view virtual override returns (uint8) {
        return decimal;
    }
}
