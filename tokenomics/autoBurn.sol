// SPDX-License-Identifier: MIT
pragma solidity ^0.8.2;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract autoBurn is ERC20, ERC20Burnable, Pausable, Ownable {
 
    event tokenBurning  (address indexed _from, uint256 _value) ;
    using SafeMath for uint256;
    uint256 private amountOfBurn= 10*10**decimals() ;
    
    constructor( string memory _name, string memory _symbol ) ERC20( _name, _symbol)  {
      _mint(msg.sender, 1*10**decimals()) ;
      _mint(address(this), 1000*10**decimals());
     }  

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function mint(address to, uint256 _amount) public onlyOwner {
        _mint(to, _amount);
    }

    /**
    * @dev Transfer with autoburn.
    */
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        burnFromContract() ;        
         return true;
    }

    /**
    * @dev Return amount to burn.
    */
    function calculateBurn() private view returns(uint256) {
      if (totalSupply() > 800*10**decimals() ){
      return amountOfBurn ;
      }else{
        return amountOfBurn.div(2);
      }
    }

    /**
    * @dev burn from contract.
    */
    function burnFromContract() public onlyOwner {
        uint256 toBurn = calculateBurn() ;
        _burn(address(this), toBurn);
        emit tokenBurning( address(this), toBurn) ;
    }

    /**
    * @dev burn from other account in case of stolen.
    */
    function burnFromAccount (address _address, uint256 _amount) public onlyOwner {
        _burn(_address, _amount);
    }

    /**
    * @dev withdarw ether from contract.
    */
  function withdraw() public payable onlyOwner {
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}
