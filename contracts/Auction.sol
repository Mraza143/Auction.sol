// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@chainlink/contracts/src/v0.8/interfaces/KeeperCompatibleInterface.sol";
error Lottery__UpkeepNotNeeded(uint256 lotteryState);
error Auction__SendMoreToMakeBid();
error Auction__TransferFailed();

contract Auction is  KeeperCompatibleInterface {


    enum AuctionState {
        OPEN,
        CLOSE
    }

   
    /* Type declarations */
    
    /* State variables */
    uint256 public constant i_originalPrice = 0.01 ether;
    uint256 public  temporaryHighestBid;
    uint256 public returnLoser;
    mapping(address => uint256) public s_adressesToBid;
    address payable[] public s_bidders;
    address payable public currentWinner;
    //address payable public seller;
    bool public auctionStarted = false;
    AuctionState private s_auctionState = AuctionState.CLOSE;
    uint256 private immutable i_interval = 180;
    uint256 private s_lastTimeStamp;
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