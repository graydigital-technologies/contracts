// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
 * @title MultiSigWallet
 * @dev A multisignature wallet contract that requires multiple owners' approvals for transactions.
 */
contract MultiSigWallet is AccessControl {
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");

    event SubmitTransaction(address indexed owner, uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event ConfirmTransaction(address indexed owner, uint256 indexed txIndex);
    event RevokeConfirmation(address indexed owner, uint256 indexed txIndex);
    event ExecuteTransaction(address indexed owner, uint256 indexed txIndex);

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
        uint256 numConfirmations;
    }

    mapping(uint256 => mapping(address => bool)) public isConfirmed;
    Transaction[] public transactions;
    uint256 public numConfirmationsRequired;

    modifier onlyOwner() {
        require(hasRole(OWNER_ROLE, msg.sender), "not owner");
        _;
    }

    modifier txExists(uint256 _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint256 _txIndex) {
        require(!transactions[_txIndex].executed, "tx already executed");
        _;
    }

    modifier notConfirmed(uint256 _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "tx already confirmed");
        _;
    }

    /**
     * @dev Constructor to initialize the contract with owners and required confirmations.
     * @param _owners Array of owner addresses.
     * @param _numConfirmationsRequired Number of confirmations required for transaction execution.
     */
    constructor(address[] memory _owners, uint256 _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(
            _numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length,
            "invalid number of required confirmations"
        );

        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setRoleAdmin(OWNER_ROLE, DEFAULT_ADMIN_ROLE);

        // Check for unique owners' addresses
        for (uint256 i = 0; i < _owners.length; i++) {
            require(_owners[i] != address(0), "invalid owner");
            require(!hasRole(OWNER_ROLE, _owners[i]), "owner not unique");
            grantRole(OWNER_ROLE, _owners[i]);
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    /**
     * @dev Submits a transaction for approval.
     * @param _to Recipient address of the transaction.
     * @param _value Amount of Ether to send in the transaction.
     */
    function submitTransaction(address _to, uint256 _value) public onlyRole(OWNER_ROLE) {
        uint256 txIndex = transactions.length;
        bytes memory withdrawData = abi.encodeWithSignature("withdraw()");

        transactions.push(Transaction({to: _to, value: _value, data: withdrawData, executed: false, numConfirmations: 0}));

        emit SubmitTransaction(msg.sender, txIndex, _to, _value, withdrawData);
    }

    /**
     * @dev Confirms a transaction.
     * @param _txIndex Index of the transaction to confirm.
     */
    function confirmTransaction(
        uint256 _txIndex
    ) public onlyRole(OWNER_ROLE) txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        transaction.numConfirmations += 1;
        isConfirmed[_txIndex][msg.sender] = true;

        emit ConfirmTransaction(msg.sender, _txIndex);
    }

    /**
     * @dev Executes a confirmed transaction.
     * @param _txIndex Index of the transaction to execute.
     */
    function executeTransaction(uint256 _txIndex) public onlyRole(OWNER_ROLE) txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(transaction.numConfirmations >= numConfirmationsRequired, "Min 3 confirmations required");

        transaction.executed = true;

        (bool success, ) = transaction.to.call{value: transaction.value}(transaction.data);
        require(success, "tx failed");

        emit ExecuteTransaction(msg.sender, _txIndex);
    }

    /**
     * @dev Revokes a previously confirmed transaction.
     * @param _txIndex Index of the transaction to revoke confirmation from.
     */
    function revokeConfirmation(uint256 _txIndex) public onlyRole(OWNER_ROLE) txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];

        require(isConfirmed[_txIndex][msg.sender], "tx not confirmed");

        transaction.numConfirmations -= 1;
        isConfirmed[_txIndex][msg.sender] = false;

        emit RevokeConfirmation(msg.sender, _txIndex);
    }

    /**
     * @dev Returns the total number of transactions.
     * @return Total number of transactions.
     */
    function getTransactionCount() public view returns (uint256) {
        return transactions.length;
    }

    /**
     * @dev Retrieves details of a specific transaction.
     * @param _txIndex Index of the transaction to retrieve details for.
     * @return to Recipient address of the transaction.
     * @return value Amount of Ether sent in the transaction.
     * @return data Data payload of the transaction.
     * @return executed True if the transaction has been executed, false otherwise.
     * @return numConfirmations Number of confirmations received for the transaction.
     */
    function getTransaction(
        uint256 _txIndex
    )
        public
        view
        txExists(_txIndex)
        returns (address to, uint256 value, bytes memory data, bool executed, uint256 numConfirmations)
    {
        Transaction storage transaction = transactions[_txIndex];

        return (transaction.to, transaction.value, transaction.data, transaction.executed, transaction.numConfirmations);
    }
}
