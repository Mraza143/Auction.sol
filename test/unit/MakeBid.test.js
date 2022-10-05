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

  it("Bid is reverted if the auction is ended", async function () {
    await network.provider.send("evm_increaseTime", [interval + 1])
    await expect(nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })).to.be.revertedWith( // is reverted as raffle is calculating
    "Auction__AuctionHasEnded"
)

  });

  it("Initializes Auction started variable correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    const auctionStarted = await nftAuction.connect(user1).getStateOfAuction(erc721.address,tokenId)
    assert.equal(auctionStarted, true)
  });

  it("Initializes Auction temporary highest  variable correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    const auctionTemporaryHighestBid = await nftAuction.connect(user1).getTemporaryHighestBid(erc721.address,tokenId)
    assert.equal(auctionTemporaryHighestBid, minPrice)
  });

  it("updates Auction bidders array  variable correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    const auctionbiddersSpecificElement = await nftAuction.connect(user1).getSpecificAddress(erc721.address,tokenId , 0)
    assert.equal(auctionbiddersSpecificElement, user1.address)
  });


  it("updates Auction current winner  variable correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    const auctionCurrentWinner = await nftAuction.connect(user1).getCurrentWinner(erc721.address,tokenId)
    assert.equal(auctionCurrentWinner, user1.address)
  });



  it("updates the mapping of addresses to bid correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    const auctionLatestBid = await nftAuction.connect(user1).getBidOfAnAddress(erc721.address,tokenId, user1.address)
    assert.equal(auctionLatestBid, minPrice)
  });


  it("updates the mapping of addresses to amount funded correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    const auctionLatestAmountFunded = await nftAuction.connect(user1).getAmountFundedByAnAddress(erc721.address,tokenId, user1.address)
    assert.equal(auctionLatestAmountFunded, minPrice)
  });

  it("updates the mapping of addresses to amount funded after consecutive bids correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice+1 })
    
    const auctionLatestAmountFunded = await nftAuction.connect(user1).getAmountFundedByAnAddress(erc721.address,tokenId, user1.address)
    assert.equal(auctionLatestAmountFunded, minPrice+1)
  });


  it("updates the mapping of addresses to bid after consecutive bids correctly", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice +10 })
    const auctionLatestBid = await nftAuction.connect(user1).getBidOfAnAddress(erc721.address,tokenId, user1.address)
    assert.equal(auctionLatestBid, minPrice + 10)
  });


  it("emits an event when a bid is initialized", async function () {
    expect(await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice })).to.emit(
      "BidMade"
  )
  });

});