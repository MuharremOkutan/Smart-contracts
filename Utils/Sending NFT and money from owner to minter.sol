// SPDX-License-Identifier: MIT

// Edited By LAx

/*
* Contract will enable WL get nfts from the wallet of the owner
* some money will be sent for the minting the customer from the contract
* the money should be first send to the contract to be then delivered to the minters
* it can work with erc20 tokens as well, just uncomment 
*/

pragma solidity >=0.7.0 <0.9.0;


import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

// interface IERC20 {
//   function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
//   function balanceOf(address account) external view returns (uint256);
//   function allowance(address owner, address spender) external view returns (uint256);
// }
interface IERC721 {
  function transferFrom(address from, address to, uint256 tokenId) external;
}


contract SimpleNftMerkleTree is Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;
    IERC721 public nftAddress ;
    // IERC20 public tokenAddress ;   //usdt mainnet 0xdAC17F958D2ee523a2206206994597C13D831ec7
    address [] investers;
    
    // Function to receive Ether. msg.data must be empty
    receive() external payable {}

    // Fallback function is called when msg.data is not empty
    fallback() external payable {}




  bytes32 public merkleRoot = 0x55d95bd20c15aedfbe840d7ba3f67eda52e020976ba24c1980d27eb1ab326c3a;

//max claiming per user rounds  
//uint public MaxClaimAmount = 10;
  //mapping variables checking if already claimed
    mapping(address => bool) public whitelistClaimed ;
  //mapping variables checking NFT amount per wallet
   uint256 public amountClaimed ;
        // Store each nft apy(ntfId->apy)
    mapping(address => uint256) public nftAmount;

    uint256 amount_gifted =0.0011 ether ;


   constructor( address  _nft) {  //,   address _tokenAddress 
     nftAddress = IERC721(_nft) ;
    //  tokenAddress= IERC20(_tokenAddress);

  }

  function totalSupply() public view returns (uint256) {
    return _tokenIdCounter.current();
  }

 
 function whitelistMint(uint256 _mintAmount, bytes32[] calldata _merkleProof) public {
    // Verify whitelist requirements
    require(!whitelistClaimed[msg.sender], "Address already claimed!");
//    require (_mintAmount <= MaxClaimAmount , "Max amount exceeded") ;     
    bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
    require(MerkleProof.verify(_merkleProof, merkleRoot, leaf), "Invalid proof!");
 

    whitelistClaimed[msg.sender] = true;
    investers.push(msg.sender) ; // to reset mapping
    _mintLoop(msg.sender, _mintAmount);
  }

  function setMerkleRoot(bytes32 _merkleRoot) public onlyOwner {
    merkleRoot = _merkleRoot;
  }

    function setNftAddress(IERC721 _nftAddress) public onlyOwner {
    nftAddress = _nftAddress;
  }

//      function setTokenAddress(IERC20 _tokenAddress) public onlyOwner {
//     tokenAddress = _tokenAddress;
//   }

  //   function setMaxAmount(uint _claimAmount) public onlyOwner {
  //   MaxClaimAmount = _claimAmount;
  // }


//reset Wl receiving
  function resetBalance() public onlyOwner {
    for (uint i=0; i< investers.length ; i++){
        whitelistClaimed[investers[i]] = false;
    }
  }

    // function usdtBalance(address _to) public view returns (uint256) {
    //       return tokenAddress.balanceOf(_to);
    // }


  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      _tokenIdCounter.increment();
         uint256 tokenId = _tokenIdCounter.current();
         //transfer nft to claimer
          nftAddress.transferFrom(owner(), _receiver,tokenId) ;       
         //send usdt
        // tokenAddress.transferFrom(owner(), _receiver, 2);  //to change to real amount
        sendViaCall(payable(_receiver), amount_gifted);
     amountClaimed+=1 ;
    }
  }

      function sendViaCall(address payable _to, uint256 value) internal  {
        // Call returns a boolean value indicating success or failure.
        // This is the current recommended method to use.
        (bool sent, bytes memory data) = _to.call{value:value}("");
        require(sent, "Failed to send Ether");
    }

    function pause() public onlyOwner {
        pause();
    }

    function unpause() public onlyOwner {
        unpause();
    }





    //   function setAmountByClaimer(address _claimer, uint256 _amount) public onlyOwner {
    //     require(_amount > 0, "nft and amount must > 0");
    //     nftAmount[_claimer] = _amount;
    // }

    //  function setAmountList(address[]  memory _users , uint[] memory _amount) public onlyOwner {
    // require(_users.length== _amount.length, "not same list");
    // for (uint i ; i<_users.length ; i++){
    //   nftAmount[_users[i]]= _amount[i];
    // }

//   }

    function setAmountGifted(uint256 _amountGifted) public onlyOwner {
          amount_gifted = _amountGifted ;
    }
  
        function getBalance() public view returns (uint) {
        return address(this).balance;
    }

      function withdraw() public payable onlyOwner {
        (bool os, ) = payable(owner()).call{value: address(this).balance}("");
        require(os);
  }


}
