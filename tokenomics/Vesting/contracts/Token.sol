// contracts/Token.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract Token is ERC20 {
    address owner ;
    constructor() ERC20("DORA", "DORA") {
        _mint(msg.sender, 25*10**26);
         owner = msg.sender;
    }

    function transferTokenVesting(address _add) public {
        require(msg.sender==owner, "Have to be contract owner");
        transfer(_add, 425*10**24);
    }
}
