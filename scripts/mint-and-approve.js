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
    //console.log("Approving NFT...")
    //console.log(tokenId.toString());
    
    const approvalTx = await erc721Mock.approve(auction.address, tokenId)
    console.log(` before approaved to ${auction.address}`)
    await approvalTx.wait(1)
    console.log(`after approaved to ${auction.address}`)
    console.log(tokenId.toString());

    console.log("getting the owner of token")
    const owner = await erc721Mock.ownerOf(tokenId);
    console.log(owner);


    console.log("get Approved")
    const approved = await erc721Mock.getApproved(tokenId);
    console.log(approved);


}

mintAndApproave()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error)
        process.exit(1)
    })