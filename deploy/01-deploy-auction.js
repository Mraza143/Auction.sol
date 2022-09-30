const { network } = require("hardhat")
const { networkConfig, developmentChains } = require("../helper-hardhat-config")
const { verify } = require("../utils/verify")

module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments
    const { deployer } = await getNamedAccounts()
    const chainId = network.config.chainId

    log("----------------------------------------------------")
    log("Deploying Lottery and waiting for confirmations...")
    const auction = await deploy("Auction", {
        from: deployer,
        args: [],
        log: true,
        // we need to wait if on a live network so we can verify properly
        waitConfirmations: network.config.blockConfirmations || 1,
    })
    log(`Lottery deployed at ${auction.address}`)

    if (
        !developmentChains.includes(network.name) &&
        process.env.ETHERSCAN_API_KEY
    ) {
        await verify(auction.address, [])
    }
}

module.exports.tags = ["all", "fundme"]


/*An Auction Contract
Many contracts can make a bid
A contract can not make consecutive bid
The highest bidder will get asset(could be anything)
The amount will be transferred from highest bidder
All the remaining bidders will be transfered back their eth.*/
