// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import "./shares.sol";


contract hash {

    //--------------- STATE ---------------//

    address public immutable MASTER;

    address public immutable SELLER;

    address public immutable BUYER;

    string public PRICE; // <-- price off chain offered by the buyer

    bytes public TIPS_ID; // <-- tips_trx_id tip environment

    bytes32 public immutable HASH_EXECUTION_KEY; // <-- hash_execution_key to force execution

    bytes32 public immutable HASH_CANCELLATION_KEY; // <-- hash_cancellation_key to force cancellation

   Status public hashStatus;



    //--------------- TOKEN ---------------//



    Share public immutable TOKEN;

    uint public immutable TOKEN_AMOUNT;


    //---------------- ERRORS ----------------//

   enum Status {
        Inizialized,
        Executed,
        Cancelled
    }

    //-------------------------------------//
    //--------------- EVENTS --------------//
    //-------------------------------------//

    event Initialized(
        address indexed _seller,
        address indexed _buyer,
        string _price,
        uint _tokenAmount,
        bytes _tipsId,
        address _token_address
    );

    event CooperativeExecution(address indexed _from, address indexed _to);
    event ForcedExecution(address indexed _from, address indexed _to);
    event CooperativeCancellation(address indexed _from, address indexed _to);
    event ForcedCancellation(address indexed _from, address indexed _to);
    //--------------- MODIFIERS --------------//



    modifier onlySeller() {
        require(msg.sender == SELLER, "Only seller can call this function");
        _;
    }

    modifier onlyBuyer() {
        require(msg.sender == BUYER, "Only buyer can call this function");
        _;
    }

    modifier onlyInitialized() {
        require(
            hashStatus == Status.Inizialized,
            "hash is not initialized"
        );
        _;
    }

   

    //--------------- CONSTRUCTOR --------------//

   

    /// @dev Initializes a new instance of the hash (Hash Link Contract) contract.

    /// @param _seller The address of the seller participating in the DvP.

    /// @param _buyer The address of the buyer participating in the DvP.

    /// @param _price The agreed price of the Share token in euro.

    /// @param _tokenAmount The amount of Share tokens to be exchanged.

    /// @param _tipsId An identifier used by tips associated with the DvP.

    /// @param _hashExecutionKey The hashed execution key required for forced execution.

    /// @param _hashCancellationKey The hashed cancellation key required for forced cancellation.

    /// @param _tokenAddress The address of the Share token that represents the Share token.




    /// Effects:

    /// - Sets all the contract's state variables.

    /// - Sets the contract status to "Initialized".


    /// Emits:

    /// - "Initialized" event with the contract details.

    constructor(
        address _seller,
        address _buyer,
        string memory _price,
        uint _tokenAmount,
        bytes memory _tipsId,
        bytes32 _hashExecutionKey,
        bytes32 _hashCancellationKey,
        address _tokenAddress
    ) {

        require(
            msg.sender != _seller,
            "hash: master address is the same as seller address"
        );

        require(
            _seller != _buyer,
            "hash: seller address is the same as buyer address"
        );

        // implicitly check _buyer != msg.sender

        require(_tokenAddress != address(0), "hash: token address is zero");

        // check hash info

        require(bytes(_price).length > 0, "hash: price is zero");

        require(
            _hashExecutionKey.length > 0,
            "hash: hash execution Key is empty"
        );

        require(
            _hashCancellationKey.length > 0,
            "hash: hash cancellation Key is empty"
        );

        require(
            _tokenAmount > 0,
            "hash: invalid token amount, must be greater than zero"
        );

        // check funds

        TOKEN = Share(_tokenAddress);

        require(
            TOKEN.balanceOf(_seller) >= _tokenAmount,
            "hash: seller has not enough token"
        );

        // assignments

        MASTER = msg.sender;

        SELLER = _seller;

        BUYER = _buyer;

        PRICE = _price;

        TOKEN_AMOUNT = _tokenAmount;

        TIPS_ID = _tipsId;

        HASH_EXECUTION_KEY = _hashExecutionKey;

        HASH_CANCELLATION_KEY = _hashCancellationKey;

        hashStatus = Status.Inizialized;

        // issue event

        emit Initialized(
            SELLER,
            BUYER,
            PRICE,
            TOKEN_AMOUNT,
            TIPS_ID,
            _tokenAddress
        );
    }

  

    function cooperativeExecution() external onlySeller onlyInitialized {
        // update status

        hashStatus = Status.Executed;

        // execute transfer to the buyer

        bool success = TOKEN.transfer(BUYER, TOKEN_AMOUNT);

        require(success, "hash: failed token transfer");

        // issue event

        emit CooperativeExecution(SELLER, BUYER);
    }

    /// @dev Allows the buyer to cancel the DvP cooperatively.

    ///

    /// Requirements:

    /// - Only the buyer can call this function.

    /// - The hash must be in the 'Initialized' status.

    ///

    /// Effects:

    /// - Transfers N Share token from the buyer to the seller.

    /// - Updates the hash status to 'Cancelled'.

    ///

    /// Emits:

    /// - 'CooperativeCancellation' event with the buyer and seller addresses.

    function cooperativeCancellation() external onlyBuyer onlyInitialized {
        // update status

        hashStatus = Status.Cancelled;

        // execute transfer to the seller

        bool success = TOKEN.transfer(SELLER, TOKEN_AMOUNT);

        require(success, "hash: failed token transfer");

        // issue event

        emit CooperativeCancellation(BUYER, SELLER);
    }

    /// @dev Allows to force the execution of the DvP by the buyer.

    /// This function can only be called by the buyer when the hash is in the 'Initialized' status.

    /// The execution is forced by providing the `_executionKey` as a parameter, which will be validated against the stored hash.

    ///

    /// @param _executionKey The execution key provided by the buyer.

    ///

    /// Requirements:

    /// - The caller must be the buyer of the hash.

    /// - The hash must be in the 'Initialized' status.

    /// - The provided `_executionKey` must match the stored hashExecutionKey.

    ///

    /// Effects:

    /// - Transfers TOKEN_AMOUNT Share token from the buyer to the seller.

    /// - Updates the status of the hash to 'Executed'.

    ///

    /// Emits:

    /// - 'ForcedExecution' event with the buyer and seller addresses.

    function forceExecution(
        string memory _executionKey
    ) external onlyBuyer onlyInitialized {
        // check execution key

        require(
            HASH_EXECUTION_KEY == sha256(abi.encodePacked(_executionKey)),
            "hash: Hash Execution Key is not valid"
        );

        // update status

        hashStatus = Status.Executed;

        // execute transfer to the seller

        bool success = TOKEN.transfer(BUYER, TOKEN_AMOUNT);

        require(success, "hash: failed token transfer");

        // issue event

        emit ForcedExecution(BUYER, SELLER);
    }

    /// @dev Allows to force the cancellation of the DvP by the seller.

    /// This function can only be called by the seller when the hash is in the 'Initialized' status.

    /// The cancellation is forced by providing the `_cancellationKey` as a parameter, which will be validated against the stored hash.

    ///

    /// @param _cancellationKey The cancellation key provided by the seller.

    ///

    /// Requirements:

    /// - The caller must be the seller of the hash.

    /// - The hash must be in the 'Initialized' status.

    /// - The provided `_cancellationKey` must match the stored hashCancellationKey.

    ///

    /// Effects:

    /// - Transfers TOKEN_AMOUNT Share token from the seller to the buyer.

    /// - Updates the status of the hash to 'Cancelled'.

    ///

    /// Emits:

    /// - 'ForcedCancellation' event with the seller and buyer addresses.

    function forceCancellation(
        string memory _cancellationKey
    ) external onlySeller onlyInitialized {
        // check cancellation key

        require(
            HASH_CANCELLATION_KEY == sha256(abi.encodePacked(_cancellationKey)),
            "hash: hash cancellation Key is not valid"
        );

        // update status

        hashStatus = Status.Cancelled;

        // execute transfer to the buyer

        bool success = TOKEN.transfer(SELLER, TOKEN_AMOUNT);

        require(success, "hash: failed token transfer");

        // issue event

        emit ForcedCancellation(SELLER, BUYER);
    }
}

