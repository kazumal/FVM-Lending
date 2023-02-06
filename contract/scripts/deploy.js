require("hardhat-deploy");
require("hardhat-deploy-ethers");

const { networkConfig } = require("../helper-hardhat-config");

const private_key = network.config.accounts[0];
const wallet = new ethers.Wallet(private_key, ethers.provider);

module.exports = async ({ deployments }) => {
  console.log("Wallet Ethereum Address:", wallet.address);
  const chainId = network.config.chainId;
  const tokensToBeMinted = networkConfig[chainId]["tokensToBeMinted"];

  //deploy Simplecoin
  const SimpleCoin = await ethers.getContractFactory("SimpleCoin", wallet);
  console.log("Deploying Simplecoin...");
  const simpleCoin = await SimpleCoin.deploy(tokensToBeMinted);
  await simpleCoin.deployed();
  console.log("SimpleCoin deployed to:", simpleCoin.address);
};
