//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract VaultBSC is Ownable {
    struct Token {
        address token;
        uint256 totalDeposit;
    }
    mapping(uint256 => Token) public tokenType; // 0 for USDT, 1 for USDC, 2 for BUSD
    uint256 public totalDeposit;
    address payable public receiver;

    event Deposit(address _caller, uint256 _amount, string _tokenType, uint256 _date);

    constructor(address[3] memory _token, address payable _receiver) {
        for (uint i = 0; i < _token.length; i++) {
            tokenType[i].token = _token[i];
        }
        receiver = _receiver;
    }

    function deposit(uint256 _amount, uint256 _tokenType) public returns (bool) {
        require(_tokenType <= 2, "Invalid token type");
        string memory token = "";
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
        return true;
    }

    function withdraw() public onlyOwner returns (bool) {
        require(totalDeposit >= 500 * 10 ** 18, "Total deposit is less than 500");
        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = IERC20(tokenType[i].token).balanceOf(address(this));
            if (balance > 0) {
                tokenType[i].totalDeposit -= balance;
                totalDeposit -= balance;
                require(IERC20(tokenType[i].token).transfer(receiver, balance), "Transfer failed!");
            }
        }
        return true;
    }

    function rescue() public onlyOwner {
        if (totalDeposit > 0) {
            totalDeposit = 0;
        }
        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = IERC20(tokenType[i].token).balanceOf(address(this));
            if (balance > 0) {
                require(IERC20(tokenType[i].token).transfer(receiver, balance), "Transfer failed!");
            }
        }
    }
}
