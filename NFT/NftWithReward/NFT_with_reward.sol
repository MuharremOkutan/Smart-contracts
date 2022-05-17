// SPDX-License-Identifier: MIT

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import"@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract SimpleNftLowerGas is ERC721, Ownable {
  using Strings for uint256;
  using Counters for Counters.Counter;

  Counters.Counter private supply;

  string public uriPrefix = "";
  string public uriSuffix = ".json";
  string public hiddenMetadataUri;
  
  uint256 public cost = 0.01 ether;
  uint256 public maxSupply = 10000;
  uint256 public maxMintAmountPerTx = 5;

  bool public paused = false;
  bool public revealed = false;

  /*
  erc20 reward 
  */

    using Address for address;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    struct RewardsPeriod {
        uint32 start;                                   // Start time for the current rewardsToken schedule
        uint32 end;                                     // End time for the current rewardsToken schedule
    }

    struct RewardsPerToken {
        uint128 accumulated;                            // Accumulated rewards per token for the period, scaled up by 1e18
        uint32 lastUpdated;                             // Last time the rewards per token accumulator was updated
        uint96 rate;                                    // Wei rewarded per second among all token holders
    }

    struct UserRewards {
        uint128 accumulated;                            // Accumulated rewards for the user until the checkpoint
        uint128 checkpoint;                             // RewardsPerToken the last time the user rewards were updated
    }


    IERC20 public rewardsToken;                         // Token used as rewards
    RewardsPeriod public rewardsPeriod;                 // Period in which rewards are accumulated by users

    RewardsPerToken public rewardsPerToken;             // Accumulator to track rewards per token               
    mapping (address => UserRewards) public rewards;    // Rewards accumulated by users




  /* */

  constructor() ERC721("NAME", "SYMBOL") {
    setHiddenMetadataUri("ipfs://__CID__/hidden.json");
  }


 /*
  erc20 reward 
  */

      /// @dev Return the earliest of two timestamps
    function earliest(uint32 x, uint32 y) internal pure returns (uint32 z) {
        z = (x < y) ? x : y;
    }


    /// @dev Set a rewards token.
    /// @notice Careful, this can only be done once.
    function setRewardsToken(IERC20 rewardsToken_)
        external
        onlyOwner
    {
        require(rewardsToken == IERC20(address(0)), "Rewards token already set");
        rewardsToken = rewardsToken_;
    }


     /// @dev Set a rewards schedule
    function setRewards(uint32 start, uint32 end, uint96 rate)
        external
        onlyOwner
    {
        require(
            start <= end,
            "Incorrect input"
        );
        require(
            rewardsToken != IERC20(address(0)),
            "Rewards token not set"
        );
        // A new rewards program can be set if one is not running
        require(
            uint32(block.timestamp) < rewardsPeriod.start || uint32(block.timestamp) > rewardsPeriod.end,
            "Ongoing rewards"
        );

        rewardsPeriod.start = start;
        rewardsPeriod.end = end;
        rewardsPerToken.lastUpdated = start;
        rewardsPerToken.rate = rate;
    }

        /// @dev Update the rewards per token accumulator.
    /// @notice Needs to be called on each liquidity event
    function _updateRewardsPerToken() internal {
        RewardsPerToken memory rewardsPerToken_ = rewardsPerToken;
        RewardsPeriod memory rewardsPeriod_ = rewardsPeriod;
        uint256 totalSupply_ = rewardsToken.totalSupply();

        // We skip the update if the program hasn't started
        if (uint32(block.timestamp) < rewardsPeriod_.start) return;

        // Find out the unaccounted time
        uint32 end = earliest(uint32(block.timestamp), rewardsPeriod_.end);
        uint256 unaccountedTime = end - rewardsPerToken_.lastUpdated; // Cast to uint256 to avoid overflows later on
        if (unaccountedTime == 0) return; // We skip the storage changes if already updated in the same block

        // Calculate and update the new value of the accumulator. unaccountedTime casts it into uint256, which is desired.
        // If the first mint happens mid-program, we don't update the accumulator, no one gets the rewards for that period.
        if (totalSupply_ != 0)
        rewardsPerToken_.accumulated = uint128(rewardsPerToken_.accumulated + 1e18 * unaccountedTime * rewardsPerToken_.rate / totalSupply_); // The rewards per token are scaled up for precision
        rewardsPerToken_.lastUpdated = end;
        rewardsPerToken = rewardsPerToken_;
        
    }


        /// @dev Accumulate rewards for an user.
    /// @notice Needs to be called on each liquidity event, or when user balances change.
    function _updateUserRewards(address user) internal returns (uint128) {
        UserRewards memory userRewards_ = rewards[user];
        RewardsPerToken memory rewardsPerToken_ = rewardsPerToken;
        
        // Calculate and update the new value user reserves. _balanceOf[user] casts it into uint256, which is desired.
        userRewards_.accumulated = uint128(userRewards_.accumulated + balanceOf(user) * (rewardsPerToken_.accumulated - userRewards_.checkpoint) / 1e18); // We must scale down the rewards by the precision factor
        userRewards_.checkpoint = rewardsPerToken_.accumulated;
        rewards[user] = userRewards_;

        return userRewards_.accumulated;    
    }





//     function calculateRewardsAndTimePassed(address _user)
//         internal
        
//     {
// require (block.timestamp <= rewardsPeriod.end, 'no drop anymore' );

//         uint256 currentBalance = rewards[_user];
//         // seconds
//         uint256 timePassed = block.timestamp.sub(rewardsPerToken.lastUpdated);
//         if (timePassed > 60 seconds) {
//             // if timePassed less than one second, rewards will be 0
//           rewards.accumulated[_user].add(rewardsPeriod.rate);
//           rewards.checkpoint[_user] = block.timestamp ;
//           rewardsPerToken.lastUpdated = block.timestamp ;
//           rewardsPerToken.accumulated.add(rewardsPeriod.rate);

//         }
//     }

    /**
     * Get reward token balance by address.
     * @param addr The address of the account that needs to check the balance.
     * @return Return balance of reward token.
     */
    function getRewardBalance(address addr) public view returns (uint256) {
        return rewardsToken.balanceOf(addr);
    }

  /* */


  modifier mintCompliance(uint256 _mintAmount) {
    require(_mintAmount > 0 && _mintAmount <= maxMintAmountPerTx, "Invalid mint amount!");
    require(supply.current() + _mintAmount <= maxSupply, "Max supply exceeded!");
    _;
  }

  function totalSupply() public view returns (uint256) {
    return supply.current();
  }

  function mint(uint256 _mintAmount) public payable mintCompliance(_mintAmount) {
    require(!paused, "The contract is paused!");
    require(msg.value >= cost * _mintAmount, "Insufficient funds!");

        _updateRewardsPerToken();
        _updateUserRewards(msg.sender)* _mintAmount; //per nft

    _mintLoop(msg.sender, _mintAmount);
   // calculateRewardsAndTimePassed(msg.sender)*_mintAmount;
  }
  
  function mintForAddress(uint256 _mintAmount, address _receiver) public mintCompliance(_mintAmount) onlyOwner {
    _mintLoop(_receiver, _mintAmount);
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory ownedTokenIds = new uint256[](ownerTokenCount);
    uint256 currentTokenId = 1;
    uint256 ownedTokenIndex = 0;

    while (ownedTokenIndex < ownerTokenCount && currentTokenId <= maxSupply) {
      address currentTokenOwner = ownerOf(currentTokenId);

      if (currentTokenOwner == _owner) {
        ownedTokenIds[ownedTokenIndex] = currentTokenId;

        ownedTokenIndex++;
      }

      currentTokenId++;
    }

    return ownedTokenIds;
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
        ? string(abi.encodePacked(currentBaseURI, _tokenId.toString(), uriSuffix))
        : "";
  }

  function setRevealed(bool _state) public onlyOwner {
    revealed = _state;
  }

  function setCost(uint256 _cost) public onlyOwner {
    cost = _cost;
  }

  function setMaxMintAmountPerTx(uint256 _maxMintAmountPerTx) public onlyOwner {
    maxMintAmountPerTx = _maxMintAmountPerTx;
  }

  function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
    hiddenMetadataUri = _hiddenMetadataUri;
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

  function withdraw() public onlyOwner {  
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

  function _mintLoop(address _receiver, uint256 _mintAmount) internal {
    for (uint256 i = 0; i < _mintAmount; i++) {
      supply.increment();
      _safeMint(_receiver, supply.current());
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return uriPrefix;
  }
}