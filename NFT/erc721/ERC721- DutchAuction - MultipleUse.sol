// SPDX-License-Identifier: MIT
// Edited by LAx

pragma solidity >=0.8.9 <0.9.0;

import 'erc721a/contracts/ERC721A.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/utils/cryptography/MerkleProof.sol';
import '@openzeppelin/contracts/security/ReentrancyGuard.sol';


contract multicall is ERC721A, Ownable, ReentrancyGuard {

    event AuctionActivated(
        address indexed sender,
        AuctionStatus status,
        uint256 timestamp
    );

   event WhitelistMintStatusChanged(
        address indexed sender,
        uint256 timestamp
    );

    event RootChanged(
        address indexed sender,
        uint256 timestamp
    );

    event SetAuctionParameter(
        address indexed sender,
        uint256 timestamp
    );

    event WlReset(
      address indexed sender,
      uint256 timestamp
    );


  bytes32 public merkleRoot;
  mapping(address => bool) public whitelistClaimed;
  address [] investers;

  string private uriPrefix ;
  string constant uriSuffix = '.json';
  string private hiddenMetadataUri;
  uint256 public wlCost = 0.1 ether;
  uint256 constant public maxSupply = 3*10**24;
  uint256 public maxMintAmountPerTx = 2;
  bool public paused = true;
  bool public whitelistMintEnabled = false;
  bool public revealed = false;
  bool public auctionACtivated = false;

  enum AuctionStatus  { open, close } 
  AuctionStatus auctionStatus ;

  /////Dutch auction functions -- change to immutable
  struct Dutch_a {
    uint256  d_startPrice;
    uint256  d_endPrice;
    uint256  d_startAt;
    uint256  d_endsAt;
    uint256  d_stepDuration;
    uint256  discountRate ;
  }

  Dutch_a public auction;


  error ContractPaused();
  error TokenNotExisting();
  error MaxSupply();
  error InvalidMintAmount();
  error InsufficientFund();
  error WhitelistClosed(); 
  error AlreadyClaimed();
  error InvalidProof();
  error AuctionNotACtivated();
  error InvalidAuctionParameters();
  error auctionAlreadyActivated();


  constructor(
    string memory _tokenName,
    string memory _tokenSymbol,
    string memory _hiddenMetadataUri
  ) ERC721A(_tokenName, _tokenSymbol) {
      setHiddenMetadataUri(_hiddenMetadataUri);
      }

  modifier mintCompliance(uint256 _mintAmount) {
    if (_mintAmount > maxMintAmountPerTx) revert InvalidMintAmount();
    if (totalSupply() + _mintAmount > maxSupply) revert MaxSupply();
    _;
  }

  function price() public view returns (uint256) {
    if (auction.d_endsAt < block.timestamp) {
        return auction.d_endPrice;
    }
//step duration = minute/hour/day...
    uint256 minutesElapsed = (block.timestamp - auction.d_startAt) / auction.d_stepDuration;

    return auction.d_startPrice - (minutesElapsed * auction.discountRate);
    }

    
  function activateAuction () public onlyOwner {
//if auction is already open don't activate
    if (auctionACtivated) revert auctionAlreadyActivated();
    if (block.timestamp>auction.d_endsAt || block.timestamp<auction.d_startAt ) revert InvalidAuctionParameters();
      auctionACtivated= true;
      emit AuctionActivated(msg.sender, AuctionStatus.open, block.timestamp); 
  }


  function deactivateAuction () public onlyOwner {
    if (auctionACtivated) auctionACtivated= false;
    //  auctionACtivated= false; 
      emit AuctionActivated(msg.sender, AuctionStatus.close, block.timestamp);
  }


  function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public payable mintCompliance(_mintAmount)  {
    if (!whitelistMintEnabled) revert WhitelistClosed();
    if(whitelistClaimed[_msgSender()]) revert AlreadyClaimed();
    bytes32 leaf = keccak256(abi.encodePacked(_msgSender()));
    if(!MerkleProof.verify(_merkleProof, merkleRoot, leaf) ) revert InvalidProof(); 
    if (msg.value < wlCost * _mintAmount) revert InsufficientFund();

    whitelistClaimed[_msgSender()] = true;
    investers.push(msg.sender) ; // to reset mapping
    _safeMint(_msgSender(), _mintAmount);
  }


// if !auctionACtivated not run
  function m_auction(uint256 _mintAmount) public payable mintCompliance(_mintAmount)  {
    uint getPrice = price();
   if (!auctionACtivated || block.timestamp >auction.d_endsAt) revert AuctionNotACtivated();
   if (paused) revert ContractPaused();
   
   if (msg.value < getPrice * _mintAmount) revert InsufficientFund();

    _safeMint(_msgSender(), _mintAmount);
  }
  
  function _startTokenId() internal view virtual override returns (uint256) {
        return 1;
  }

  function tokenURI(uint256 _tokenId) public view virtual override returns (string memory) {
    if (!_exists(_tokenId)) revert TokenNotExisting();

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, _toString(_tokenId), uriSuffix))
        : '';
  }

  function setRevealed() public onlyOwner {
    revealed = !revealed;
  }

  function setWlCost(uint256 _cost) public onlyOwner {
    wlCost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
  }

  function setUri(string memory _uriPrefix) public onlyOwner {
    uriPrefix = _uriPrefix;
  }

//   function setUriSuffix(string memory _uriSuffix) public onlyOwner {
//     uriSuffix = _uriSuffix;
//   }

  function setPaused() public onlyOwner {
    paused = !paused;
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

  function setWhitelistMintEnabled(bool _state) public onlyOwner {
    whitelistMintEnabled = _state;
     emit WhitelistMintStatusChanged(msg.sender, block.timestamp);
  }

  ///Dutch auctions parameters

//set DutchStart Date
  function setAuction( uint256  _d_startPrice,  uint256  _d_endPrice,uint256  _d_startAt, uint256  _d_endsAt,   uint256  _discountRate, uint256 _d_stepDuration ) public onlyOwner {
    if (_d_startAt>_d_endsAt ||  _d_startPrice<_d_endPrice  || block.timestamp>_d_startAt || auctionACtivated ) revert InvalidAuctionParameters();   
     auction = Dutch_a(_d_startPrice , _d_endPrice , _d_startAt,  _d_endsAt  ,  _discountRate, _d_stepDuration);
     emit SetAuctionParameter(msg.sender, block.timestamp);
  } 

//reset wl mapping mint
  function resetBalance() public onlyOwner {
    for (uint i=0; i< investers.length ; i++){
        whitelistClaimed[investers[i]] = false;
    emit WlReset(msg.sender, block.timestamp);
    }
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
}