// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";
contract MyToken is ERC20 {
    address owner ;
    constructor(string memory _name, string memory _symbol) ERC20(_name, _symbol) {
        _mint(msg.sender, 1 * 10 ** decimals());
        _mint(address(this) , 20999999 * 10 ** decimals());
        owner = msg.sender;
    }

}


    

