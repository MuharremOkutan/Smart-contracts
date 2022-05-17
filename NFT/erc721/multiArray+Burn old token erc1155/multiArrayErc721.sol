// SPDX-License-Identifier: MIT
// Edited by LAx

/*contract having 3 functions with WL array
*regularWL -- where user can mint whatever NFTS he wants, using regularWL
*BurnWL - burn old token from opensea and emit a new one using addBurnWL for WL array, openseaCollection to check 
*mintSeveral - minting without wl
*/

pragma solidity >=0.8.9 <0.9.0;

import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';
import './myerc1155.sol';
import '@openzeppelin/contracts/token/ERC721/ERC721.sol';
import '@openzeppelin/contracts/utils/Counters.sol';


contract BlackMap is ERC721,  Ownable, ReentrancyGuard {

  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = 'ipfs://replace with base uri/';
  string public uriSuffix = '.json';
  // string public hiddenMetadataUri;
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 8008;
  uint256 public maxMintAmountPerTx = 10;
  uint256 public maxMintAmount= 10;
  bool public paused = false;
  bool public publicSale = false;
  bool public tempPause = false;
  // bool public whitelistMintEnabled = true;
  mapping(address => mapping (uint => OpenseaCollection)) public openseaCollection;
//counter for the nested mapping
  mapping (address => uint) private cntToMint;
  //amount for regular WL
  mapping(address => uint) public regularWhitelisted;


  struct OpenseaCollection {
    uint newToken ;
    uint oldToken ;
    }


   ERC1155 public erc1155contract ;

  constructor() ERC721("_tokenName", "_tokenSymbol") {
    // opensea NFT address
       erc1155contract = ERC1155(0x2953399124F0cBB46d2CbACD8A89cF0599974963);    
  }


    modifier mintCompliance(uint256[] memory tokenId) {
    require(supply.current() + tokenId.length <= maxSupply, "Max supply exceeded!");
    require(!paused, 'The contract is paused!'); 
    require(tokenId.length > 0 && tokenId.length <= maxMintAmountPerTx, "Invalid mint amount!");
    _;
  }



  function regularWL (uint256[] memory tokenId) public  mintCompliance(tokenId) {
    require(regularWhitelisted[msg.sender]>0, "You are not Whitelisted");
    require(tempPause,'Minting season has yet to arrived!');
    require(balanceOf(msg.sender) + tokenId.length <= regularWhitelisted[msg.sender], "Not enough minting left");
    mintingloop(tokenId);
  }

 
 ///burn wl
  function BurnWL (address _receiver) public {
    require(!paused, 'The contract is paused!');
    require(cntToMint[_receiver]>0, "You are not Whitelisted");
        for (uint i=1; i<= cntToMint[_receiver]; i++){
      uint newT = openseaCollection[_receiver][i].newToken;
      uint oldT = openseaCollection[_receiver][i].oldToken;
      //has opensea old token
        require(checkbalanceErc1155(oldT)>0, 'Not opensea token owner');              
      erc1155contract.burn(_receiver, oldT ,checkbalanceErc1155(oldT) ) ;
      supply.increment();
      _safeMint(_msgSender(), newT); 
      //delete the user spot 
       delete openseaCollection[_receiver][i];
         }
         //delete the nuber of token to mint
       delete cntToMint[_receiver];
  }


 
// mint several tokenIds
  function mintSeveral(uint256[] memory tokenId) public payable mintCompliance(tokenId) {
    require(tokenId.length + balanceOf(msg.sender) <= maxMintAmount, 'Too much minted');
    require(tempPause,'Minting season has yet to arrived!');
    require(publicSale, 'The contract is not open!');
    require(msg.value >= cost*tokenId.length , 'Insufficient funds!');
    mintingloop(tokenId);
  }


  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function checkbalanceErc1155 (uint tokenId) private view  returns(uint){
      return erc1155contract.balanceOf(msg.sender, tokenId) ;
  }

  //gifting function
  function mintForAddress(uint256 tokenId , address _receiver) public onlyOwner {
   _safeMint(_receiver, tokenId);
  }


  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    require(_exists(_tokenId), 'ERC721Metadata: URI query for nonexistent token');
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : '';
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }  

    function setMaxMintAmount(uint256 _maxMintAmount) public onlyOwner {
    maxMintAmount = _maxMintAmount;
  } 

  function setUriPrefix(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

  function setUriSuffix(string memory _uriSuffix) public onlyOwner {
    uriSuffix = _uriSuffix;
  }

  function setPaused(bool _state) public onlyOwner {
    paused = _state;
  }

  function setPublicSale(bool _state) public onlyOwner {
    publicSale = _state;
  }  
    function setTempPause(bool _state) public onlyOwner {
    tempPause = _state;
  }
 
  function setMaxSupply(uint supplyNumber) public onlyOwner {
    maxSupply = supplyNumber;
  }  

  function withdraw() public onlyOwner nonReentrant {
    // =============================================================================
    (bool os, ) = payable(owner()).call{value: address(this).balance}('');
    require(os);
    // =============================================================================
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }

  function addRegularWhitelistUser(address _user, uint _amount) 
    public onlyOwner
  {        
    regularWhitelisted[_user] =_amount;    
  }
 
 function removeRegularWhitelistUser(address _user) public onlyOwner {
    delete regularWhitelisted[_user];
  }

  //add to burnWL
  function addBurnWl (address _user, uint _id , uint _tokenId, uint _openSeaToken) public onlyOwner {
   openseaCollection[_user][_id] =   OpenseaCollection(_tokenId , _openSeaToken);
   cntToMint[_user] +=1;
    }


  function mintingloop(uint256[] memory tokenId) internal {
    for (uint i=0; i<tokenId.length; i++){
      supply.increment();
      _safeMint(_msgSender(), tokenId[i]);
    }
  }

}


