const { assert, expect } = require("chai")
const { network, deployments, ethers ,getNamedAccounts } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { BigNumber } = require("ethers");

let tokenId;
const minPrice = 2;
const lessThanMinPrice=1;
const interval = 86; 



// Deploy and create a mock erc721 contract.
// 1 basic test, NFT sent from one person to another works correctly.
describe("NFTAuction", function () {
  let ERC721;
  let erc721;
  let NFTAuction;
  let nftAuction;
  let user1;
  let user2;

  beforeEach(async () => {

    ERC721 = await ethers.getContractFactory("ERC721Mock");
    NFTAuction = await ethers.getContractFactory("Auction");
    [ContractOwner, user1, user2, user3, testArtist, testPlatform] =
      await ethers.getSigners();
    erc721 = await ERC721.deploy();
    await erc721.deployed();
    const mintTx = await erc721.connect(user1).mintNft();
    const mintTxReceipt = await mintTx.wait(1)
    tokenId = mintTxReceipt.events[0].args.tokenId
    nftAuction = await NFTAuction.deploy();
    await nftAuction.deployed();
    await erc721.connect(user1).approve(nftAuction.address, tokenId.toString());
    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
  });




  it("Bid is reverted if we send less amount of eth than minimum Price", async function () {
    await expect(nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:lessThanMinPrice })).to.be.revertedWith( // is reverted as raffle is calculating
    "Auction__SendMoreToMakeBid"
)

  });

  //await network.provider.send("evm_increaseTime", [interval.toNumber() + 1])

  it("Bid is reverted if the auction is ended", async function () {
    await network.provider.send("evm_increaseTime", [interval + 1])
    await expect(nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })).to.be.revertedWith( // is reverted as raffle is calculating
    "Auction__AuctionHasEnded"
)

  });

});