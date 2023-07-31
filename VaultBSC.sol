//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultBSC is Ownable {
    struct Token {
        address token;
        uint256 totalDeposit;
    }

    mapping(uint256 => Token) public tokenType; // 0 for USDT, 1 for USDC, 2 for BUSD
    uint256 public totalDeposit;
    address payable public immutable receiver;
    uint256 public constant MAX_REGISTERED_TOKENS = 3;

    event Deposit(address _caller, uint256 _amount, string _tokenType, uint256 _date);

    constructor(address[MAX_REGISTERED_TOKENS] memory _token, address payable _receiver) {
        require(_receiver != address(0), "Zero address not allowed");
        for (uint i = 0; i < MAX_REGISTERED_TOKENS; i++) {
            tokenType[i].token = _token[i];
        }
        receiver = _receiver;
    }

    function deposit(uint256 _amount, uint256 _tokenType) public {
        require(_tokenType <= 2, "Invalid token type");
        string memory token;
        totalDeposit += _amount;
        tokenType[_tokenType].totalDeposit += _amount;
        if (_tokenType == 0) {
            token = "USDT";
        } else if (_tokenType == 1) {
            token = "USDC";
        } else if (_tokenType == 2) {
            token = "BUSD";
        }
        require(IERC20(tokenType[_tokenType].token).transferFrom(msg.sender, address(this), _amount), "Transfer failed");
        emit Deposit(msg.sender, _amount, token, block.timestamp);
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < MAX_REGISTERED_TOKENS; i++) {
            uint256 balance = IERC20(tokenType[i].token).balanceOf(address(this));
            if (balance > 0) {
                tokenType[i].totalDeposit -= balance;
                totalDeposit -= balance;
                require(IERC20(tokenType[i].token).transfer(receiver, balance), "Transfer failed!");
            }
        }
    }
}
