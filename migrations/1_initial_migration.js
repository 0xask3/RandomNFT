const RandomNFT = artifacts.require("RandomNFT");

module.exports = function (deployer) {
  deployer.deploy(RandomNFT);
};
