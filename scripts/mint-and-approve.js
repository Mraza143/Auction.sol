const { ethers, network } = require("hardhat")


async function mintAndApproave() {
    //Getting the contract of Auction
    const auction = await ethers.getContract("Auction")
    //Getting the contract of ERC721Mock
    const erc721Mock = await ethers.getContract("ERC721Mock")

    //We are minting a nft for our auction contract
    console.log("Minting NFT...")
    const mintTx = await erc721Mock.mintNft()
    const mintTxReceipt = await mintTx.wait(1)
    const tokenId = mintTxReceipt.events[0].args.tokenId

     //We are approving the auction contract adress for the minted nft so that it can transfer the nft
    console.log("Approving NFT...")
    console.log(tokenId.toString());
    const approvalTx = await erc721Mock.approve(auction.address, tokenId)
    await approvalTx.wait(1)
   
    if (network.config.chainId == 31337) {

    }
}

mintAndApproave()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })