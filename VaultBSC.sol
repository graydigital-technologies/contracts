// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title VaultBSC
 * @dev This contract represents a vault on the Binance Smart Chain (BSC) where users can deposit and withdraw
 * different types of ERC20 tokens. The contract tracks the total deposits and individual token balances
 * for registered token types (USDT, USDC, and BUSD).
 */
contract VaultBSC is Ownable {
    struct Token {
        address token;         // Address of the ERC20 token contract
        uint256 totalDeposit;  // Total amount of this token deposited
    }

    mapping(uint256 => Token) public tokenType;

    uint256 public totalDeposit;

    address payable public immutable receiver;

    address public immutable multisig;

    uint256 public constant MAX_REGISTERED_TOKENS = 3;

    /**
     * @dev Modifier to ensure that only the multisig contract can call certain functions.
     */
    modifier onlyMultisig() {
        require(msg.sender == multisig, "Caller not multisig contract");
        _;
    }

    /**
     * @dev Event emitted when a deposit is made.
     * @param _caller The address of the depositor.
     * @param _amount The amount deposited.
     * @param _tokenType The type of token deposited (USDT, USDC, BUSD).
     * @param _date The timestamp of the deposit.
     */
    event Deposit(address _caller, uint256 _amount, string _tokenType, uint256 _date);

    /**
     * @dev Constructor to initialize the VaultBSC contract.
     * @param _token An array of addresses representing the ERC20 token contracts for each registered token type.
     * @param _receiver The address that will receive withdrawal transfers.
     * @param _multisig The address of the multisignature contract for managing the vault.
     */
    constructor(address[MAX_REGISTERED_TOKENS] memory _token, address payable _receiver, address _multisig) {
        require(_receiver != address(0), "Zero address not allowed");
        for (uint i = 0; i < MAX_REGISTERED_TOKENS; i++) {
            tokenType[i].token = _token[i];
        }
        receiver = _receiver;
        multisig = _multisig;
    }

    /**
     * @dev Function to deposit funds of a specific token type.
     * @param _amount The amount of tokens to deposit.
     * @param _tokenType The type of token to deposit (0 for USDT, 1 for USDC, 2 for BUSD).
     */
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

    /**
     * @dev Function to withdraw funds from the vault (only callable by the multisig contract).
     */
    function withdraw() public onlyMultisig {
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
