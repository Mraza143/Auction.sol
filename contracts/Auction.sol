// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

contract Auction{
    error Auction__SendMoreToMakeBid();
    error Auction__TransferFailed();
    /* Type declarations */
    
    /* State variables */
    uint256 public constant i_originalPrice = 0.01 ether;
    uint256 public  temporaryHighestBid;
    mapping(address => uint256) public s_adressesToBid;
    address payable[] public s_bidders;

     function makeBid() public payable {
        if (msg.value < temporaryHighestBid ) {
            revert Auction__SendMoreToMakeBid();
        }

        if (msg.value < i_originalPrice ) {
            revert Auction__SendMoreToMakeBid();
        }
        temporaryHighestBid= msg.value;
        s_bidders.push(payable(msg.sender));
        s_adressesToBid[msg.sender]= msg.value;
         (bool success, ) = address(this).call{value: msg.value}("");
        // require(success, "Transfer failed");
        if (!success) {
            revert Auction__TransferFailed();
        }

    }

function getNumberOfPlayers() public view returns (uint256) {
        return address(this).balance;
    }

}