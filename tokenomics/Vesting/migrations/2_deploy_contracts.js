const TokenVesting = artifacts.require("TokenVesting")
const Token = artifacts.require("Token")


module.exports = (deployer) => {
  return deployer
    .then(() => deployer.deploy(Token))          
    .then(() => deployer.deploy(TokenVesting, Token.address))
    .then(() => Token.deployed())
    .then(token => token.transferTokenVesting(TokenVesting.address))
    .then(() => TokenVesting.deployed())
    .then(vesting => vesting.deploy())
  } ;

