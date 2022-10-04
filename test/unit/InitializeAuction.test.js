const { assert, expect } = require("chai")
const { network, deployments, ethers ,getNamedAccounts } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")
const { BigNumber } = require("ethers");

let tokenId;
const minPrice = 1;
const interval = 86; 



// Deploy and create a mock erc721 contract.
// 1 basic test, NFT sent from one person to another works correctly.
describe("NFTAuction", function () {
  let ERC721;
  let erc721;
  let NFTAuction;
  let nftAuction;
  let user1;

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
  });

  it("Checks that the owner of the nft is equal to deployer", async function () {
    expect(await erc721.ownerOf(tokenId)).to.equal(user1.address);
  });

  it("Initialize Auction initializes interval correctly", async function () {
    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
    const auctionInterval = await nftAuction.connect(user1).getIntervalOfNftAuction(erc721.address,tokenId)

    assert.equal(auctionInterval, interval)
  });



  it("Initialize Auction initializes minPrice correctly", async function () {
    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
    const auctionMinPrice = await nftAuction.connect(user1).getBeginningPriceOfTheNft(erc721.address,tokenId)
    assert.equal(auctionMinPrice, minPrice)
  });

  it("reverts if the msg.sender is not the nft owner", async function () {
    await expect(nftAuction.connect(user2).InitializeAuction(erc721.address, tokenId ,minPrice , interval)).to.be.revertedWith( // is reverted as raffle is calculating
    "You dont own the nft"
)
    /*expect(await nftAuction.connect(user2).InitializeAuction(erc721.address, tokenId ,minPrice , interval)).to.be.revertedWith(
      "You dont own the nft")*/

    })

  it("Initialize Auction initializes temporary Highest Bid correctly", async function () {
    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
    const auctionTemporaryHighestPrice = await nftAuction.connect(user1).getTemporaryHighestBid(erc721.address,tokenId)

    assert.equal(auctionTemporaryHighestPrice, minPrice)
  });


  it("Initialize Auction initializes nft seller correctly", async function () {
    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
    const auctionnftSeller = await nftAuction.connect(user1).getSellerOfTheNft(erc721.address,tokenId)

    assert.equal(auctionnftSeller, user1.address)
  });


  it("the contract is now the owner of the nft", async function () {
    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
    //const auctionnftSeller = await nftAuction.connect(user1).getSellerOfTheNft(erc721.address,tokenId)
    const owner = await erc721.ownerOf(tokenId);
    assert.equal(owner, nftAuction.address)
  });


  it("Initialize Auction initializes nft starting time correctly", async function () {

    await nftAuction.connect(user1).InitializeAuction(erc721.address, tokenId ,minPrice , interval)
    const auctionStartingTime = await nftAuction.connect(user1).getStartingTimeOfAuction(erc721.address,tokenId)
    const bNumBefore = await ethers.provider.getBlockNumber();
    const bBefore = await ethers.provider.getBlock(bNumBefore);
    const timestampB = bBefore.timestamp;
    assert.equal(auctionStartingTime, timestampB);
  });
});