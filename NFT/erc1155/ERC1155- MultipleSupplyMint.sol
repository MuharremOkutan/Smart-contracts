// SPDX-License-Identifier: MIT
//edited by LAx
/*
* erc1155 with multiple rates, multiple rarity, multiple supply
*/


pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts@4.4.2/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts@4.4.2/access/Ownable.sol";
import "@openzeppelin/contracts@4.4.2/security/Pausable.sol";
import "@openzeppelin/contracts@4.4.2/token/ERC1155/extensions/ERC1155Supply.sol";

/// @custom:security-contact ddddd
contract MyToken is ERC1155, Ownable, Pausable, ERC1155Supply {

    uint256 common =10;
    uint256 uncommon= 5;
    uint256 rare =2 ;
    uint256 superRare = 1;

    uint256 common_rates =0.001 ether;
    uint256 uncommon_rates= 0.003 ether;
    uint256 rare_rates =0.009 ether ;
    uint256 superRare_rates = 0.04 ether;

    uint256[] rates = [common_rates, uncommon_rates, uncommon_rates ,uncommon_rates];
    uint256[] supplies = [common, rare, superRare, common] ;
    uint256[] minted= [0,0,0,0] ;
    bool public revealed = false;
    uint16 maxPerWallet = 5 ;
    mapping (address => uint256) public balanceOfAll ;


//name , symbol in metadata
// uri i.e ipfs://xxxxx/{id}.json
    constructor(
        string memory _initNotRevealedUri
              )ERC1155(_initNotRevealedUri) {
    }

    function setURI(string memory newuri) public onlyOwner {
        require(revealed, "Collection not revealed");
        _setURI(newuri);
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function reveal() public onlyOwner {
       revealed = true;
    }

    modifier limitBuyamount (uint256 id, uint256 amount) {
        require(amount<=maxPerWallet, "Exceeded limit per wallet" );
        require(balanceOf(msg.sender,id)+amount<=maxPerWallet,"Exceeded limit per wallet");
        _;
    }

    function mint(uint256 id, uint256 amount)
        public payable limitBuyamount(id, amount)
    {
        require(id <= supplies.length, "Token does not exist");
        require(id > 0, "Token does not exist");
        
        uint256 index = id -1 ;
        require(minted[index]+ amount <= supplies[index], "Not enough tokens");
        
        require(msg.value >= rates[index]*amount,"Not enough money");
        _mint(msg.sender, id, amount, " ");
        minted[index]+= amount;
        balanceOfAll[msg.sender] +=amount ;
    }

    function setCommonCost(uint256 _newCost) public onlyOwner {
        common_rates = _newCost;
    }

        function setUncommonCost(uint256 _newCost) public onlyOwner {
        uncommon_rates = _newCost;
    }

        function setRareCost(uint256 _newCost) public onlyOwner {
        rare_rates = _newCost;
    }

        function setSuperRareCost(uint256 _newCost) public onlyOwner {
        superRare_rates = _newCost;
    }

 
    // function mintBatch(uint256[] memory ids, uint256[] memory amounts)
    //      public payable        
    // {
    //     _mintBatch(msg.sender, ids, amounts, "");
    // }

    function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data)
        internal
        whenNotPaused
        override(ERC1155, ERC1155Supply)
    {
        super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
    }


    function withdraw() public payable onlyOwner {    
        require(address(this).balance>0, "Not enough balance");

        (bool hs, ) = payable(0x479eec2Ed1Da9Ec2e8467EF1DC72fd9cE848e1C3).call{value: address(this).balance * 50 / 100}("");
         require(hs);
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
    
     }
}
