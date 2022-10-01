// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
error Lottery__UpkeepNotNeeded(uint256 lotteryState);
error Auction__SendMoreToMakeBid();
error Auction__TransferFailed();

contract Auction is  KeeperCompatibleInterface {

    //mapping from a nft(adress + token Id) to a Auction
    mapping(address => mapping(uint256 => Auction)) public nftContractAuctions;
    
    
     struct Auction {

        uint32  i_interval; // For How much time does the nft seller want the auction to continue
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
    enum AuctionState {
        OPEN,
        CLOSE
    }

   
    /* Type declarations */
    
    /* State variables */
    //uint256 public constant i_originalPrice = 0.01 ether;
    //uint256 public  temporaryHighestBid;
    //uint256 public returnLoser;
    //mapping(address => uint256) public s_adressesToBid;
    
    //address payable public currentWinner;
    //address payable public seller;
    //bool public auctionStarted = false;
    //AuctionState private s_auctionState = AuctionState.CLOSE;
    //uint256 private immutable i_interval = 180;
    //uint256 private s_lastTimeStamp;
    mapping(address => uint256) private s_addressToAmountFunded;


     function makeBid() public payable {
        if (msg.value < temporaryHighestBid ) {
            revert Auction__SendMoreToMakeBid();
        }
        if (msg.value < i_originalPrice ) {
            revert Auction__SendMoreToMakeBid();
        }
        if(auctionStarted){
           returnLoser = s_adressesToBid[currentWinner];
            (bool success, ) = currentWinner.call{value: returnLoser}("");
        }

        temporaryHighestBid= msg.value;
        s_bidders.push(payable(msg.sender));
        currentWinner = payable(msg.sender);
        s_adressesToBid[msg.sender]= msg.value;
        s_auctionState = AuctionState.OPEN;
        s_lastTimeStamp = block.timestamp;
        // (bool success, ) = address(this).call{value: msg.value}("");
        // require(success, "Transfer failed");
         s_addressToAmountFunded[msg.sender] += msg.value;
        auctionStarted = true;


    }

 function checkUpkeep(
        bytes memory /* checkData */
    )
        public
        view
        override
        returns (
            bool upkeepNeeded,
            bytes memory /* performData */
        )
    {
        bool isOpen = AuctionState.OPEN == s_auctionState;
        bool timePassed = ((block.timestamp - s_lastTimeStamp) > i_interval);
        upkeepNeeded = (timePassed && isOpen);
        return (upkeepNeeded, "0x0"); 
    }

    function performUpkeep(
        bytes calldata /* performData */
    ) external override {
        (bool upkeepNeeded, ) = checkUpkeep("");
        require(upkeepNeeded, "Upkeep not needed");
        if (!upkeepNeeded) {
            revert Lottery__UpkeepNotNeeded(
                uint256(s_auctionState)
            );
        }
        //We will transfer nft here
        s_auctionState = AuctionState.CLOSE;
        s_bidders = new address payable[](0);


    }

}