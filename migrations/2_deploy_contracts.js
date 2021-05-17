const VotingByToken = artifacts.require("./VotingByToken.sol");

module.exports = function(deployer) {
  deployer.deploy(VotingByToken,["zhangsan","lisi","wangwu"],600,web3.toWei(1,'ether'),{from:web3.eth.accounts[0]});
};
