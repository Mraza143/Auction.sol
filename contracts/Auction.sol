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

contract Auction {
    //mapping from a nft(adress + token Id) to a Auction
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;


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
        uint128 minPrice; // The price of the nft  at which the auction will start
        uint256 s_lastTimeStamp; //The time at which the auction will start
        address payable[] s_bidders; // The colletion of all the adresses which have made a bid for the nft
        mapping(address => uint256) s_adressesToBid; //A mapping of all the addresses to their bid , so we can return their amount in case their bid did not win nft
        mapping(address => uint256) s_addressToAmountFunded; // A mapping to receive bids
        uint256 temporaryHighestBid; // The highest bid made for a nft at any given moment
        uint128 nftHighestBid; //The bid which won the nft
        address payable currentWinner; //The adress which is currently winning the auction , at the end of the auction , this will automatically get set to the final winner
        address nftSeller; // The address of the seller of the nft
        bool auctionStarted; // A bool to keep track whether the auction has started or not ;
    }

    //This Function will be called by the nft owner to initialize the auction and specify
    // and specify their  custom parameters
    //The user will have the choice to specify for how many duration does he want the auction to continue
    // And what will be the starting price of the nft
    function InitializeAuction(
        address _nftContractAddress,
        uint256 _tokenId,
        uint128 _minPrice,
        uint32 interval
    ) public {
        nftContractAuctions[_nftContractAddress][_tokenId].i_interval = interval;
        nftContractAuctions[_nftContractAddress][_tokenId].minPrice = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid = _minPrice;
        nftContractAuctions[_nftContractAddress][_tokenId].nftSeller = msg.sender;
        nftContractAuctions[_nftContractAddress][_tokenId].s_lastTimeStamp = block.timestamp;

        //Now transfering the Nft from the seller to this contract adress
        //We will transfer only if the creator of auction is the owner of Nft .
        require(IERC721(_nftContractAddress).ownerOf(_tokenId) == msg.sender,
        "You dont own the nft"
        );

            IERC721(_nftContractAddress).transferFrom(
                msg.sender,
                address(this),
                _tokenId
            );
            require(
                IERC721(_nftContractAddress).ownerOf(_tokenId) == address(this),
                "failed to tranfer nft"
            );
    }

    //This function will be called whenever a address  will make a bid
    // We will do all the necessary checks that whether our bid is valid or not
    //After the checks we will change the state variable of the smart contract
    //After changing the state we will transfer funds from the adress who made the bid to contract

    function makeBid(address _nftContractAddress, uint256 _tokenId) public payable {
         //We need to call this if statetement to check whether the bid amount is grater than the previous 
        //bid and also better than the minimum price setted by the nft seller

        if (
            msg.value < nftContractAuctions[_nftContractAddress][_tokenId].minPrice ||
            msg.value < nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid
        ) {
            revert Auction__SendMoreToMakeBid();
        }

        //We need to call this function everytime except the first bid as the auction would not have properly started
        //We basically revert the transaction if the Auction Time has ended

        if (
            block.timestamp - nftContractAuctions[_nftContractAddress][_tokenId].s_lastTimeStamp >
            nftContractAuctions[_nftContractAddress][_tokenId].i_interval
        ) {
            //If this if statement return true then this means the auction period has ended but no 
            //one has bided for the nft
            if(nftContractAuctions[_nftContractAddress][_tokenId].minPrice==nftContractAuctions[_nftContractAddress][_tokenId].temporaryHighestBid){
                ///We transfer the nft back to the seller from the contract
                IERC721(_nftContractAddress).transferFrom(
                address(this),
                msg.sender,               
                _tokenId
            );
            }
            revert Auction__AuctionHasEnded();
        }

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
    }

    //This function will be called by nft auction winner and it will transfer the nft from contract 
    //to theadress of the nft winner
    function receiveNft(address _nftContractAddress, uint256 _tokenId) public{
        //Checking if the caller is the nft auction winner
        if(
            msg.sender!=nftContractAuctions[_nftContractAddress][_tokenId].currentWinner
            ){
            revert Auction__NotAuctionWinner();
        }
        //Checking if the auction has ended
         if (
            block.timestamp - nftContractAuctions[_nftContractAddress][_tokenId].s_lastTimeStamp <
            nftContractAuctions[_nftContractAddress][_tokenId].i_interval
        ) {
            revert Auction__AuctionNotEndedYet();
    }
    //Transfering the nft to the winner
    IERC721(_nftContractAddress).transferFrom(
                address(this),
                msg.sender,               
                _tokenId
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
        returns (uint128)
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