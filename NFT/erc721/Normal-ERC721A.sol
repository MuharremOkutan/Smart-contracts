// SPDX-License-Identifier: MIT
// Edited by LAx

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';

contract TundraWolves is ERC721A, Ownable, ReentrancyGuard {


  string public uriPrefix ;
  string public hiddenMetadataUri = "ipfs://__CID__/hidden.json";

  string public uriSuffix = '.json';
  uint256 public cost = 0.04  ether;
  uint256 public maxSupply = 1500;
  uint256 public maxMintAmountPerTx = 4;
  bool public paused = false;
  bool public revealed = false;

  constructor() ERC721A("Tundra Wolves", "TW") {
    hiddenMetadataUri;
}

  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, 'Invalid mint amount!');
    require(totalSupply() + _mintAmount <= maxSupply, 'Max supply exceeded!');
    _;
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount){
    require(!paused, 'The contract is paused!');
      if (msg.sender != owner()) {
        require(msg.value >= cost * _mintAmount, 'Insufficient funds!');   
    }  
    _safeMint(_msgSender(), _mintAmount);
  }
  

  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
    }

  function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI,  _toString(_tokenId), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

    function setUri(string memory _uriPrefix) public onlyOwner {
    uriPrefix = string(abi.encodePacked('ipfs://', _uriPrefix, '/'));
  }


  //  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
  //   hiddenMetadataUri = _hiddenMetadataUri;
  // }

    function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }



  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool pd, ) = payable(0x7AcB122c3cEd6ad1e8abD16A5Ef4C53324CFF33f).call{value: address(this).balance * 5 / 100}("");
    require(pd);

    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}