const { assert, expect } = require("chai")
const { network, deployments, ethers ,getNamedAccounts } = require("hardhat")
const { developmentChains, networkConfig } = require("../../helper-hardhat-config")

!developmentChains.includes(network.name)
    ? describe.skip
    : describe("Nft Auction Contract Unit Tests", function () {
          let lottery, deployer, interval, player

          beforeEach(async () => {
              accounts = await ethers.getSigners() 
              deployer  = (await getNamedAccounts()).deployer
              player = accounts[1]
              await deployments.fixture(["all"])
              auction = await ethers.getContract("Auction",deployer) 
          })

          describe("InitializeAuction", function () {
              it("initializes the auction interval variable correctly", async () => {
                  //const lotteryState = (await lottery.getLotteryState()).toString()
                  auction.InitializeAuction('0x00000', 1 ,1 , 60)
                  assert.equal(auction.nftContractAuctions[_nftContractAddress][_tokenId], "0")
                  assert.equal(
                      interval.toString(),
                      networkConfig[network.config.chainId]["keepersUpdateInterval"]
                  )
              })             
          })        
              })

