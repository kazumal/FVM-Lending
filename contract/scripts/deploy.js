require("hardhat-deploy");
require("hardhat-deploy-ethers");

const { networkConfig } = require("../helper-hardhat-config");

const private_key = network.config.accounts[0];
const wallet = new ethers.Wallet(private_key, ethers.provider);

module.exports = async ({ deployments }) => {
  console.log("Wallet Ethereum Address:", wallet.address);
  const chainId = network.config.chainId;
  const tokensToBeMinted = networkConfig[chainId]["tokensToBeMinted"];

  //deploy LoanMarket
  const LendingMarket = await ethers.getContractFactory("LendingMarket", wallet);
  console.log("Deploying LendingMarket...");
  const lendingMarket = await LendingMarket.deploy(tokensToBeMinted);
  await lendingMarket.deployed();
  console.log("LendingMarket deployed to:", lendingMarket.address);
};
