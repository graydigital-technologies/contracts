//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

// This is a custom interface specific to USDT on ETH because it does not conform to the ERC20 standard (the function transferFrom does not return a Boolean).
interface IERC20 {
    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `to`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address to, uint256 amount) external;

    /**
     * @dev Moves `amount` tokens from `from` to `to` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address from, address to, uint256 amount) external;
}

contract VaultETH is Ownable {
    struct Token {
        address token;
        uint256 totalDeposit;
    }

    mapping(uint256 => Token) public tokenType; // 0 for USDT, 1 for USDC, 2 for BUSD
    uint256 public totalDeposit;
    address payable public immutable receiver;
    uint256 public constant MAX_REGISTERED_TOKENS = 3;

    event Deposit(address indexed _caller, uint256 _amount, string _tokenType, uint256 _date);

    constructor(address[MAX_REGISTERED_TOKENS] memory _token, address payable _receiver) {
        require(_receiver != address(0), "Zero address for not allowed");
        for (uint i = 0; i < _token.length; i++) {
            tokenType[i].token = _token[i];
        }
        receiver = _receiver;
    }

    function deposit(uint256 _amount, uint256 _tokenType) public {
        require(_tokenType <= 2, "Invalid token type");
        string memory token = "";
        _tokenType == 0 || _tokenType == 1 ? totalDeposit += _amount * 10 ** 12 : totalDeposit += _amount;
        tokenType[_tokenType].totalDeposit += _amount;
        if (_tokenType == 0) {
            token = "USDT";
        } else if (_tokenType == 1) {
            token = "USDC";
        } else if (_tokenType == 2) {
            token = "BUSD";
        }
        IERC20(tokenType[_tokenType].token).transferFrom(msg.sender, address(this), _amount);
        emit Deposit(msg.sender, _amount, token, block.timestamp);
    }

    function withdraw() public onlyOwner {
        for (uint256 i = 0; i < MAX_REGISTERED_TOKENS; i++) {
            uint256 balance = IERC20(tokenType[i].token).balanceOf(address(this));
            if (balance > 0) {
                tokenType[i].totalDeposit -= balance;
                i == 0 || i == 1 ? totalDeposit -= balance * 1000000000000 : totalDeposit -= balance;
                IERC20(tokenType[i].token).transfer(receiver, balance);
            }
        }
    }
}
