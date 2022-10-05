// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
/*
    **************************************************************************************

                POSSIBLE ERRORS WHICH CAN BE EXPECTED DURING EXECUTION

    ***************************************************************************************

*/
error Auction__AuctionHasEnded();
error Auction__SendMoreToMakeBid();
error Auction__TransferFailed();
error Auction__NotAuctionWinner();
error Auction__AuctionNotEndedYet();
error Auction__NotAuctionNftSeller();
error Auction__AuctionHaveBids();
error Auction__AuctionDontHaveBids();
error Auction__NotNftOwner();

contract Auction {
    /*
    **************************************************************************************

                STRUCTURES USED FOR THE SMART CONTRACT

    ***************************************************************************************

*/
    //This is how our Action Object Will look Like
    //This will have the following properties
    //Out o these , the user will have the ability to customize 2 of them which are minprice and interval
    
    struct Auction {
        uint32 i_interval; // For How much time does the nft seller want the auction to continue
        uint256 minPrice; // The price of the nft  at which the auction will start
        uint256 s_lastTimeStamp; //The time at which the auction will start
        address payable[] s_bidders; // The colletion of all the adresses which have made a bid for the nft
        mapping(address => uint256) s_adressesToBid; //A mapping of all the addresses to their bid , so we can return their amount in case their bid did not win nft
        mapping(address => uint256) s_addressToAmountFunded; // A mapping to receive bids
        uint256 temporaryHighestBid; // The highest bid made for a nft at any given moment
        address payable currentWinner; //The adress which is currently winning the auction , at the end of the auction , this will automatically get set to the final winner
        address nftSeller; // The address of the seller of the nft
        bool auctionStarted; // A bool to keep track whether the auction has started or not ;
    }

     /*
    **************************************************************************************

                EVENTS WHICH WILL BE EMITTED DURING EXECUTION OF SMART CONTRACT

    ***************************************************************************************

*/

//This event will be emitted when a instance of Auction is inititialized by the seller
  event AuctionInitialized(
        address indexed nftAdress,
        uint256 indexed tokenId,
        address indexed nftSellerAdress,
        uint256 minprice,
        uint32 interval
    );

    
//This Event will be emitted when a  bid is made by a adress
 event BidMade(
        address indexed nftAdress,
        uint256 indexed tokenId,
        address indexed bidMakerAddress,
        uint256 price
    );

//This Event will be emitted when a  auction winner receives the nft After the auction has ended
 event WinNftAfterAuction(
        address indexed nftAdress,
        uint256 indexed tokenId,
        address indexed nftWinnerAddress,
        uint256 finalPrice
    );


 //This Event will be emitted when a  auction ended without no winner , and the seller of the nft gets
 //the nft back to his address
 event WithdrawNftAfterAuctionUnsuccesful(
        address indexed nftAdress,
        uint256 indexed tokenId,
        address indexed nftsellerAddress
    );


 //This Event will be emitted when a  auction ended with a succesful bid , and the seller of the nft gets
 //the winning bid transferred to his wallet
 event ReceiveWinningBidAfterAuction(
        address indexed nftAdress,
        uint256 indexed tokenId,
        address indexed nftsellerAddress,
        uint256 winningBid
        
    );

     //State Variables

     //mapping from a nft(adress + token Id) to a Auction
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;


     /*
    **************************************************************************************

                MODIFIERS TO ENHANCE CODE READABLITY

    ***************************************************************************************

*/
//This Modifier will check whether the caller of function is indeed the owner of the nft
modifier isOwner(
        address nftAddress,
        uint256 tokenId,
        address spender
    ) {
        IERC721 nft = IERC721(nftAddress);
        address owner = nft.ownerOf(tokenId);
        if (spender != owner) {
            revert Auction__NotNftOwner();
        }
        _;
    }

//This modifier will check whether the bid made is a valid bid by checking if the msg.value is grater than
//the minimum price of the nft as well as the previous Highest bid

modifier isBidValid(
        address nftAddress,
        uint256 tokenId,
        uint256 bidAmount
    ) {
        if (bidAmount < nftContractAuctions[nftAddress][tokenId].temporaryHighestBid
        ) {
            revert Auction__SendMoreToMakeBid();
        }
        _;
    }

//This modifier will check whether the auction has ended or not

modifier isAuctionEnded(
        address nftAddress,
        uint256 tokenId
    ) {
          if (
            block.timestamp - nftContractAuctions[nftAddress][tokenId].s_lastTimeStamp >
            nftContractAuctions[nftAddress][tokenId].i_interval
        ) {
            revert Auction__AuctionHasEnded();
        }
        _;
    }


//This modifier will check whether the caller of the function is the auction winner

modifier isAuctionWinner(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
          if(
            sender!=nftContractAuctions[nftAddress][tokenId].currentWinner
            ){
            revert Auction__NotAuctionWinner();
        }
        _;
    }


//This modifier will check whether the caller of the function is the seller of the nft or not

modifier isAuctionNftSeller(
        address nftAddress,
        uint256 tokenId,
        address sender
    ) {
          if(
            sender!=nftContractAuctions[nftAddress][tokenId].nftSeller
            ){
            revert Auction__NotAuctionNftSeller();
        }
        _;
    }

//This modifier will check whether the auction has any bids

modifier isAuctionBidded(
        address nftAddress,
        uint256 tokenId
    ) {
        if(
            nftContractAuctions[nftAddress][tokenId].minPrice!=nftContractAuctions[nftAddress][tokenId].temporaryHighestBid
        ){
            revert Auction__AuctionHaveBids();
    }
        _;
    }

//This modifier will check whether the auction has no bids

modifier isAuctionNotBidded(
        address nftAddress,
        uint256 tokenId
    ) {
        if (
nftContractAuctions[nftAddress][tokenId].minPrice==nftContractAuctions[nftAddress][tokenId].temporaryHighestBid
        ) {
            revert Auction__AuctionDontHaveBids();
    }
        _;
    }

       /*
    **************************************************************************************

                Initializing Auction And Making Bids Functions

    ***************************************************************************************

*/

    //This Function will be called by the nft owner to initialize the auction and specify
    // and specify their  custom parameters
    //The user will have the choice to specify for how many duration does he want the auction to continue
    // And what will be the starting price of the nft
    function InitializeAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint256 _minPrice,
        uint32 interval
    ) public
    isOwner(_nftContractAddress , _tokenId , msg.sender)
     {
        nftContractAuctions[_nftContractAddress][_tokenId].i_interval = interval;
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        nftContractAuctions[_nftContractAddress][_tokenId].s_lastTimeStamp = block.timestamp;


            IERC721(_nftContractAddress).transferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "failed to tranfer nft"
            );
            emit AuctionInitialized(
                _nftContractAddress,
                _tokenId,
                msg.sender,
                _minPrice,
                interval
            );
    }

    //This function will be called whenever a address  will make a bid
    // We will do all the necessary checks that whether our bid is valid or not
    //After the checks we will change the state variable of the smart contract
    //After changing the state we will transfer funds from the adress who made the bid to contract

    function makeBid(
        address _nftContractAddress,
        uint256 _tokenId)
          public
          payable
          isBidValid(_nftContractAddress,_tokenId, msg.value)
          isAuctionEnded(_nftContractAddress,_tokenId)

            {
        //We need to call this function everytime except the first bid as there will be no one to
        //receive their failed bids

        if (nftContractAuctions[_nftContractAddress][_tokenId].auctionStarted) {
            //We return the funds to the previous bid , as we already have a better bid
            (bool success, ) = nftContractAuctions[_nftContractAddress][_tokenId]
                .currentWinner
                .call{
                value: nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid
            }("");
        }
        nftContractAuctions[_nftContractAddress][_tokenId].auctionStarted = true;
        nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid = msg.value;
        nftContractAuctions[_nftContractAddress][_tokenId].s_bidders.push(payable(msg.sender));
        nftContractAuctions[_nftContractAddress][_tokenId].currentWinner = payable(msg.sender);
        nftContractAuctions[_nftContractAddress][_tokenId].s_adressesToBid[msg.sender] = msg.value;
        nftContractAuctions[_nftContractAddress][_tokenId].s_addressToAmountFunded[
            msg.sender
        ] += msg.value;

        emit BidMade(
                _nftContractAddress,
                _tokenId,
                msg.sender,
                msg.value
            );
    }
       /*
    **************************************************************************************

                These functions will be called after the auction has ended

    ***************************************************************************************

*/

    //This function will be called by nft auction winner and it will transfer the nft from contract 
    //to theadress of the nft winner
    function receiveNft(
        address _nftContractAddress,
        uint256 _tokenId)
          public
          isAuctionEnded(_nftContractAddress,_tokenId)
          isAuctionWinner(_nftContractAddress,_tokenId,msg.sender)
          {

    //Transfering the nft to the winner
    IERC721(_nftContractAddress).transferFrom(
                address(this),
                msg.sender,               
                _tokenId
            );

            emit WinNftAfterAuction(
                _nftContractAddress,
                _tokenId,
                msg.sender,
                nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid              
            );
  }

    //This function will be called by the seller of the nft if there was no bid on the auction
    //Meaning the Auction Failed
    function withdrawNft(
        address _nftContractAddress,
        uint256 _tokenId)
        public
        isAuctionEnded(_nftContractAddress,_tokenId)
        isAuctionNftSeller(_nftContractAddress,_tokenId,msg.sender)
        isAuctionBidded(_nftContractAddress,_tokenId)
        
        {

    //Transfering the nft to the seller from the contract
    IERC721(_nftContractAddress).transferFrom(
                address(this),
                nftContractAuctions[_nftContractAddress][_tokenId].nftSeller,               
                _tokenId
            );
            emit WithdrawNftAfterAuctionUnsuccesful(
                _nftContractAddress,
                _tokenId,
                msg.sender
            );
  }

  //This function will be called by the seller of the nft if the auction was succesful
  function withdrawWinningBid(
    address _nftContractAddress,
    uint256 _tokenId)
     public
     isAuctionEnded(_nftContractAddress,_tokenId)
     isAuctionNftSeller(_nftContractAddress,_tokenId,msg.sender)
     isAuctionNotBidded(_nftContractAddress,_tokenId)
     {

    //Transfering the winning bid to the nft seller account
    (bool success, ) = nftContractAuctions[_nftContractAddress][_tokenId]
                .nftSeller
                .call{
                value: nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid//At this point the temporary highestbid will become the highest bid
            }("");

            emit ReceiveWinningBidAfterAuction(
                _nftContractAddress,
                _tokenId,
                msg.sender,
                nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid
            );
  }
/*
    ******************************************************

                GETTER FUNCTIONS PUBLIC

    ******************************************************

*/

    //This function will return a temporary highest bid for a specific Nft Auction
    //At the end of the auction it will automatically be the final price for which the nft has been sold
    //If the nft does not get sold it will remain in its default value ie 0
    function getTemporaryHighestBid(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid;
    }

     //This function will return a temporary highest bidder for a specific Nft Auction(current winner)
    //At the end of the auction it will automatically be the adrees to which the nft has been sold
    //If the nft does not get sold it will remain in its default value ie 0x0000000000000000...
    function getCurrentWinner(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (address)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].currentWinner;
    }


     //This function will return a interval for which the auction will continue(in seconds) for a specific Nft Auction(current winner)

    function getIntervalOfNftAuction(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (uint32)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].i_interval;
    }


     //This function will return the beggining price provided to us the by the nft seller

    function getBeginningPriceOfTheNft(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].minPrice;
    }


    //This function will return the beggining price provided to us the by the nft seller

    function getSellerOfTheNft(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (address)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].nftSeller;
    }

    //This function will return the time at which the Auction started in epoch Time

    function getStartingTimeOfAuction(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (uint256)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].s_lastTimeStamp;
    }


    //This function will return whether the Auction is ongoing or not

    function getStateOfAuction(address _nftContractAddress, uint256 _tokenId)
        public
        view
        returns (bool)
    {
        return nftContractAuctions[_nftContractAddress][_tokenId].auctionStarted;
    }
}