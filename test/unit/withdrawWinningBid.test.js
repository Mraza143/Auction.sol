const { assert, expect } = require("chai")
const { network, deployments, ethers ,getNamedAccounts } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { BigNumber } = require("ethers");

let tokenId;
const minPrice = 2;
const lessThanMinPrice=1;
const interval = 86; 



// Deploy and create a mock erc721 contract.
describe("NFTAuction", function () {
  let ERC721;
  let erc721;
  let NFTAuction;
  let nftAuction;
  let user1;
  let user2;

  beforeEach(async () => {
    NFTAuction = await ethers.getContractFactory("Auction");
    ERC721 = await ethers.getContractFactory("ERC721Mock");

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


  it("function is reverted if the auction has not ended yet 2", async function () {

    //await network.provider.send("evm_increaseTime", [interval + 1])
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice + 1 })

    await expect(nftAuction.connect(user1).withdrawWinningBid(erc721.address, tokenId)).to.be.revertedWith( // is reverted as raffle is calculating
    "Auction__AuctionNotEndedYet"
)

  });

  it("function is reverted if the caller is not the nft auction seller 2", async function () {
    await nftAuction.connect(user1).makeBid(erc721.address, tokenId ,{value:minPrice + 1 })
    await network.provider.send("evm_increaseTime", [interval + 1])

    await expect(nftAuction.connect(user2).withdrawWinningBid(erc721.address, tokenId)).to.be.revertedWith( // is reverted as raffle is calculating
    "Auction__NotAuctionNftSeller"
)
  });
  
  it("function is reverted if the auction dont have bids", async function () {
    //await nftAuction.connect(user2).makeBid(erc721.address, tokenId ,{value:minPrice + 1})
    await network.provider.send("evm_increaseTime", [interval + 1])

    await expect(nftAuction.connect(user1).withdrawWinningBid(erc721.address, tokenId)).to.be.revertedWith( // is reverted as raffle is calculating
    "Auction__AuctionDontHaveBids"
)
  });



  it("emits an event when  receive nft is called 2", async function () {
    await nftAuction.connect(user2).makeBid(erc721.address, tokenId ,{value:minPrice + 1})
    await network.provider.send("evm_increaseTime", [interval + 1])

    expect(await nftAuction.connect(user1).withdrawWinningBid(erc721.address, tokenId)).to.emit(
      "ReceiveWinningBidAfterAuction"
  )
  });

});