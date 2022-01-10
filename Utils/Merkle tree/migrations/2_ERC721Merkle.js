const ERC721Merkle  = artifacts.require("ERC721Merkle");

module.exports = function (deployer) {
  deployer.deploy(ERC721Merkle, 'Name', 'Symbol','0xc3eab78290634fbd80cff93728ee7f9269164b8ef8fccbd2cb74ac0dae3a8c98');
};



//look at https://www.youtube.com/watch?v=62f757RVEvU