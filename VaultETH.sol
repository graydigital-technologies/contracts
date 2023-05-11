//SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";

// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IERC20 {
    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

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
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

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
    address payable public receiver;
    event Deposit(address indexed _caller, uint256 _amount, string _tokenType, uint256 _date);

    constructor(address[3] memory _token, address payable _receiver) {
        for (uint i = 0; i < _token.length; i++) {
            tokenType[i].token = _token[i];
        }
        receiver = _receiver;
    }

    function deposit(uint256 _amount, uint256 _tokenType) public returns (bool) {
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
        return true;
    }

    function withdraw() public onlyOwner returns (bool) {
        require(totalDeposit >= 500 * 10 ** 18, "Total deposit is less than 500");

        for (uint256 i = 0; i < 3; i++) {
            uint256 balance = IERC20(tokenType[i].token).balanceOf(address(this));
            if (balance > 0) {
                tokenType[i].totalDeposit -= balance;
                i == 0 || i == 1 ? totalDeposit -= balance * 1000000000000 : totalDeposit -= balance;
                IERC20(tokenType[i].token).transfer(receiver, balance);
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
                IERC20(tokenType[i].token).transfer(receiver, balance);
            }
        }
    }
}
