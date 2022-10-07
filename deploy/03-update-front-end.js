const {
    frontEndContractsFile,
    frontEndAbiLocation,
} = require("../helper-hardhat-config")
require("dotenv").config()
const fs = require("fs")
const { network } = require("hardhat")

module.exports = async () => {
    if (process.env.UPDATE_FRONT_END) {
        console.log("Writing to front end...")
        await updateContractAddresses()
        await updateAbi()
        console.log("Front end written!")
    }
}

async function updateAbi() {
    const auction = await ethers.getContract("Auction")
    fs.writeFileSync(
        `${frontEndAbiLocation}Auction.json`,
        auction.interface.format(ethers.utils.FormatTypes.json)
    )


    const basicNft = await ethers.getContract("ERC721Mock")
    fs.writeFileSync(
        `${frontEndAbiLocation}ERC721Mock.json`,
        basicNft.interface.format(ethers.utils.FormatTypes.json)
    )
}

async function updateContractAddresses() {
    const chainId = network.config.chainId.toString()
    const auction = await ethers.getContract("Auction")
    const contractAddresses = JSON.parse(fs.readFileSync(frontEndContractsFile, "utf8"))
    if (chainId in contractAddresses) {
        if (!contractAddresses[chainId]["Auction"].includes(auction.address)) {
            contractAddresses[chainId]["Auction"].push(auction.address)
        }
    } else {
        contractAddresses[chainId] = { Auction: [auction.address] }
    }
    fs.writeFileSync(frontEndContractsFile, JSON.stringify(contractAddresses))
}
module.exports.tags = ["all", "frontend"]