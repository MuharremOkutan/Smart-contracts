// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Merkle is ERC721 {
    bytes32 immutable public root;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
       //the root of merkeltree
        root = merkleroot;
    }

//mapping variables checking if already claimed
    mapping(address => bool) public whitelistClaimed ;

    function whitelistMint(bytes32[] calldata _merkleProof) public  {
        
        require(whitelistClaimed[msg.sender], "address has already claimed");
        //check if account is in whitelist
        bytes32 leaf=  keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof , root, leaf),"Invalid merkle proof");
        //mark address as having claimed their token 
            whitelistClaimed[msg.sender]= true ;    

        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId );
        _tokenIds.increment();
    }


}