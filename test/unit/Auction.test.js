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
});