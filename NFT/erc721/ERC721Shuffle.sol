//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

/*
*Edited by LAx
*/

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@1001-digital/erc721-extensions/contracts/RandomlyAssigned.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract Rooster is ERC721, Ownable,Pausable, RandomlyAssigned {
  using Strings for uint256;
  string private uriPrefix = "ipfs://QmaYNGeYCwbSV2umCAxufCNWCP1TXF5qsqAZzdsLv6S8ve";
  string public hiddenMetadataUri;
  uint256 public cost = 10 ether;
  uint256 public maxSupply =852;
  bool public revealed = false;

//for random cost
  uint256 internal EndPrice = 77 ether ;
  uint256 internal startPrice = 10 ether; 



  constructor() 
    ERC721("WierdRoosterPunk", "WRP")
    RandomlyAssigned(maxSupply,1) // Max. 852 NFTs available; Start counting from 1 (instead of 0) --Random NFTS
    { 
      setHiddenMetadataUri(uriPrefix);
      mintAtBeginnig () ;
    }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
  }

  function pause() public onlyOwner {
        _pause();
  }

  function unpause() public onlyOwner {
        _unpause();
  }

  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, tokenId);
  }

    
  function mint () public payable {
     
     require( availableTokenCount()>0, "No more tokens available");
     setCost();
      if (msg.sender != owner()) {  
        require( msg.value >= cost, "Insufficient funds!");
      }      
      uint256 id = nextToken();
        _safeMint(msg.sender, id);
        
  }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require( _exists(_tokenId),"ERC721Metadata: URI query for nonexistent token" );

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), ".json"))
        : "";
  }

  function reveal(bool _state) public onlyOwner {
      revealed = _state;
  }


//for random cost based on start and endprice
  function setCost() internal {
      uint256 maxIndex = EndPrice - startPrice;
      uint256 random = uint256(keccak256(
        abi.encodePacked(
        msg.sender,
        block.coinbase,
        block.difficulty,
        block.gaslimit,
        block.timestamp
          )
        )) % maxIndex;    
        if (random == 0 || random <startPrice) {
          cost = random+startPrice;
        } else {
          cost = random;
        }
  }


  function mintAtBeginnig () internal {
     
     require( availableTokenCount()>0, "No more tokens available");   
     for (uint i=1; i<=15; i++){
      uint256 id = nextToken();
        _safeMint(0x32d0785552020cE9E479c56dB182A5CB2b438338, id);
  }
    for (uint i=1; i<=3; i++){
        uint256 id = nextToken();
            _safeMint(msg.sender, id);
    }        
  }


  function setStartPrice (uint256 _startPrice) public onlyOwner {
      startPrice = _startPrice;
  }

  function setEndPrice (uint256 _EndPrice) public onlyOwner {
      EndPrice = _EndPrice;
  }

  function _baseURI() internal view virtual override returns (string memory) {
      return uriPrefix;
  }

  function seturi(string memory _uriPrefix) public onlyOwner {
      uriPrefix = _uriPrefix;
  }

  
  function withdraw() public payable onlyOwner {
      (bool hs, ) = payable(0x64aa437486d4425a9A1c11F0a4603Df41221aAb0).call{value: address(this).balance * 50 / 100}("");
      require(hs);
      (bool os, ) = payable(0x32d0785552020cE9E479c56dB182A5CB2b438338).call{value: address(this).balance}("");
      require(os);
  }

}