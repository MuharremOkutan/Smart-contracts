// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract ERC721Merkle is ERC721 {
    bytes32 immutable public root;
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;
//mapping variables checking if already claimed
    mapping(address => bool) public whitelistClaimed ;


    constructor(string memory name, string memory symbol, bytes32 merkleroot)
    ERC721(name, symbol)
    {
       //the root of merkeltree 0xcded7ad242cc200cdd6d8df47c33f4adbe33d096989dc2b75f769350f5d28b3d
        root = merkleroot;
        
    }



    function whitelistMint(bytes32[] calldata _merkleProof) public  {
        
        require(!whitelistClaimed[msg.sender], "address has already claimed");
        //check if account is in whitelist
        bytes32 leaf=  keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(_merkleProof ,root ,leaf ),"Invalid merkle proof");
        //mark address as having claimed their token 
            whitelistClaimed[msg.sender]= true ;    

        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId );
        _tokenIds.increment();
    }
// ["0xc906ed9eccaff091c34bf9c35cf235c880bb4638d7c4d81d3cb43b33a51bdb9e","0x698936bf018472d2efcb9cb1161f899ab3297c76b8d0ce86d116a7a6f02e8627","0x37ae2602fd2241072d4e461f9817e9b233c6b2764caffef912ff25b110d9e29d","0xf1952f4a69a27d27b8537c6948c418d6fd33ced9adffed80271af1cc3ab16d80"]
//address 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4


