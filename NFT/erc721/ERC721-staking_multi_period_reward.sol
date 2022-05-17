//SPDX-License-Identifier: Unlicense
/*
*Edited by LAx
*erc721 staking ,for different periods of staking
*differents rewards per token_id number
*for each period different rewards will be accumulated
*claiming rewards by token_id number
*
*/


pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "https://github.com/umi-digital/umi-multi-staking/blob/main/contracts/ERC20Interface.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

/**
 * nft staking farm
 */
contract NftStakingFarm is
    Context,
    Ownable,
    ReentrancyGuard,
    Pausable,
    ERC721Holder
{
    using Address for address;
    using SafeMath for uint256;
  //  using Calculator for uint256;

    /**
     * Emitted when a user store farming rewards(ERC20 token).
     * @param sender User address.
     * @param amount Current store amount.
     * @param timestamp The time when store farming rewards.
     */
    event ContractFunded(
        address indexed sender,
        uint256 amount,
        uint256 timestamp
    );

        /**
     * Emitted when a user stakes tokens(ERC20 token).
     * @param sender User address.
     * @param balance Current user balance.
     * @param timestamp The time when stake tokens.
     */
    event Staked(address indexed sender, uint256 balance, uint256 timestamp);

    /**
     * Emitted when a new nft reward is set.
     * @param tokenId A new reward value.
     */


    event NftApySet(uint256 tokenId, uint8 reward, uint256 time );

    /**
     * Emitted when a user stakes nft token.
     * @param sender User address.
     * @param nftId The nft id.
     * @param timestamp The time when stake nft.
     */
    event NftStaked(
        address indexed sender,
        uint256 nftId,
        uint256 timestamp
    );

    /**
     * Emitted when a user unstake nft token.
     * @param sender User address.
     * @param nftId The nft id.
     * @param timestamp The time when unstake nft.
     */
    event NftUnstaked(
        address indexed sender,
        uint256 nftId,
        uint256 timestamp
    );

     /**
     * @dev Emitted when a user withdraw interest only.
     * @param sender User address.
     * @param interest The amount of interest.
     * @param claimTimestamp claim timestamp.
     */
    event Claimed(
        address indexed sender,
        uint256 interest,
        uint256 claimTimestamp
    );

    // input stake token
    ERC20Interface immutable public rewardToken;
    // nft token contract
    IERC721 immutable public nftContract;

    // ERC20 about
      // // The stake balances of users, to send founds later on
     mapping(address => uint256) private balances;
     // // The farming rewards of users(address => total amount)
   //  mapping(address => uint256) private funding;

    // // The total farming rewards for users
     uint256 private totalFunding;

    // ERC721 about

    // Store each nft apy(ntfId->apy)
    uint256 private nftApys;
    // token users reveived (user address->amount))
   mapping(address => uint256) public tokenReceived;

    // Store user's nft ids(user address -> NftSet)
    mapping(address => NftSet) userNftIds;
    // The total nft staked amount
    uint256 public totalNftStaked;
    // To store user's nft ids, it is more convenient to know if nft id of user exists
    struct NftSet {
        // user's nft id array
        uint256[] ids;        //
        uint256[] nftTimes;   //time startStaked
        uint256[] nftPeriodStaking;  //nft period of staking
        // nft id -> bool, if nft id exist
        mapping(uint256 => bool) isIn;
    }

    // other constants
    
       // reward by id - royal or cub
    mapping(uint256 => uint8) private nftdailyrewards; 

//apy for different staking period, 400 is 4%
mapping(uint256=>uint256) public APYS ;
//periods in second 5min=300 sec
mapping(uint256=>uint256) public periods ;

    constructor(address _tokenAddress, address _nftContract) {
        require(
            _tokenAddress.isContract() && _nftContract.isContract(),
            "must be contract address"
        );
        rewardToken = ERC20Interface(_tokenAddress);
        nftContract = IERC721(_nftContract);
        initRewards();

    }

    /**
     * Store farming rewards to UmiStakingFarm contract, in order to pay the user interest later.
     *
     * Note: _amount should be more than 0
     * @param _amount The amount to funding contract.
     */
    function fundingContract(uint256 _amount) external nonReentrant onlyOwner {
        require(_amount > 0, "fundingContract _amount should be more than 0");
        uint256 allowance = rewardToken.allowance(msg.sender, address(this));        
        require(allowance >= _amount, "Check the token allowance");

      //  funding[msg.sender] += _amount;
        // increase total funding
        totalFunding=totalFunding.add(_amount);
        require(
            rewardToken.transferFrom(msg.sender, address(this), _amount),
            "fundingContract transferFrom failed"
        );
        // send event
        emit ContractFunded(msg.sender, _amount, _now());
    }

         /**
     * Set apy of nft.
     *
     * Note: set rewards for each nft like for the royal
     */
    function setNftReward(uint256 id, uint8 reward) public onlyOwner {
        require(id > 0 && reward > 0, "nft and apy must > 0");
        nftdailyrewards[id] = reward;
        emit NftApySet(id, reward , _now() );
    }

       function setAPYS(uint _ApyId, uint256 _newValue) public onlyOwner{
        APYS[_ApyId]= _newValue ;
    }

       function setPeriod(uint _PeriodId, uint256 _newValue) public onlyOwner{
        periods[_PeriodId]= _newValue ;
    }


    /**
     * stake nft token to this contract.
     * Note: It calls another internal "_stakeNft" method. See its description.
     */
    function stakeNft(uint256 id, uint256 periodStaking
    ) external whenNotPaused nonReentrant {
       _stakeNft(msg.sender, address(this), id, periodStaking);
    }
	

	/**
     * Transfers `_value` tokens of token type `_id` from `_from` to `_to`.
     *
     * Note: when nft staked, apy will changed, should recalculate balance.
     * update nft balance, nft id, totalNftStaked.
     *
     * @param _from The address of the sender.
     * @param _to The address of the receiver.
     * @param _id The nft id.
     */
    function _stakeNft(
        address _from,
        address _to,
        uint256 _id,
        uint256 _periodStaking
    ) internal {
        //4 period staking
          require( _periodStaking  > 0  && _periodStaking <= 4, "Not right staking period");
        // modify user's nft id array
        setUserNftIds(_from, _id, _now(),_periodStaking  );
        totalNftStaked = totalNftStaked.add(1);
        
        // transfer nft token to this contract
        nftContract.safeTransferFrom(_from, _to, _id);
        // send event
        emit NftStaked(_from, _id,  _now());
    }

  
    /**
     * Unstake nft token from this contract.
     *
     * Note: It calls another internal "_unstakeNft" method. See its description.
     *
     * @param id The nft id.
     */
    function unstakeNft(
        uint256 id
    ) external whenNotPaused nonReentrant {
        _unstakeNft(id);
    }

    /**
     * Unstake nft token with sufficient balance.
     *
     * Note: when nft unstaked, apy will changed, should recalculate balance.
     * update nft balance, nft id and totalNftStaked.
     *
     * @param _id The nft id.
     */
    function _unstakeNft(
        uint256 _id
    ) internal {
        // recalculate balance of umi token
        recalculateBalance(msg.sender, _id);

     //   uint256 nftBalance = nftBalancesStacked[msg.sender];
        require(
             getUserNftIdsLength(msg.sender) > 0,
            "insufficient balance for unstake"
        );
        // reduce total nft amount
        totalNftStaked = totalNftStaked.sub(1);
  
            // remove nft id from array
        removeUserNftId(_id); 

        // transfer nft token from this contract
        nftContract.safeTransferFrom(
            address(this),
            msg.sender,
            _id
        );
        // //withdraw reward too
        require(
            rewardToken.transfer(msg.sender, balances[msg.sender]),
            "claim: transfer failed"
        );   
        tokenReceived[msg.sender] = tokenReceived[msg.sender].add(balances[msg.sender]);
        // send event
        emit NftUnstaked(msg.sender, _id, _now());
    }


    /**
    * Withdraws the interest only of user, and updates the stake date, balance and etc..
    */
    function claimRewardById(uint256 _id) external whenNotPaused nonReentrant {
       require( getUserNftIdsLength(msg.sender) >= 0 , "No Nts Stocked");
        require(totalFunding>0 , "No enough tokens");     

        // calculate total balance with interest
        recalculateBalance(msg.sender, _id);       
        //remove the beginning reward
        uint256 balance = balances[msg.sender];
        require(balance > 0, "balance should more than 0");
        uint256 claimTimestamp = _now();
        // transfer interest to user
        require(
            rewardToken.transfer(msg.sender, balance),
            "claim: transfer failed"
        );
        //amount of token recieved
         tokenReceived[msg.sender] = tokenReceived[msg.sender].add(balances[msg.sender]);
        balances[msg.sender]=0;

        // send claim event
        emit Claimed(msg.sender, balance, claimTimestamp);
    }

    /**
     * Recalculate user's balance.
     *
     * Note: when should recalculate
     * case 1: unstake nft
     * case 2: claim reward
     */
    function recalculateBalance(address _from, uint256 _id) internal {

        // calculate total balance with interest
        (uint256 totalWithInterest, uint256 timePassed) =
            calculateRewardsAndTimePassed(_from, _id);
        require(
            timePassed >= 0,
            "NFT and reward unlocked after lock time "
        );
        balances[_from] = balances[_from].add(totalWithInterest);
    }

  
/*
*  periodtype =1  -  45days lock 
*  periodtype =2  -  30days
*  periodtype =3  -15days
*  periodtype =4  - 7days
*/

//check if he can withdraw a token he didn't inserted

        function calculateRewardsAndTimePassed(address _user, uint256 _id)
        internal
        returns (uint256, uint256)
    {
   
        NftSet storage nftSet = userNftIds[_user];
        uint256[] storage ids = nftSet.ids;
        uint256[] storage stakingStartTime = nftSet.nftTimes;
        uint256[] storage stakingPeriod = nftSet.nftPeriodStaking;

         require(isNftIdExist(_user,_id),"nft is not staked");
         uint256 stakeDate ;
         uint256 periodtype;

        // find nftId index
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == _id) {
              stakeDate  = stakingStartTime[i] ;
              periodtype  = stakingPeriod[i] ;     
              //reset time for getting reward
              stakingStartTime[i] = _now();
            }
        }

        //period of staking     
        uint256 period = periods[periodtype] ;
        uint256 timePassed = _now().sub(stakeDate);     
         if (timePassed < period) {
            // if timePassed less than one day, rewards will be 0
            return (0, timePassed);
        }
        //check if royal or normal cub
        uint reward = nftdailyrewards[_id]>0 ?  nftdailyrewards[_id] : 10 ;
        uint256 _days = timePassed.div(period);
        uint256 totalWithInterest = _days.mul(APYS[periodtype]).mul(reward).div(100);

        return (totalWithInterest, timePassed);    
    }


    /**
     * Get umi token balance by address.
     * @param addr The address of the account that needs to check the balance.
     * @return Return balance of umi token.
     */
    function getTokenBalance(address addr) public view returns (uint256) {
        return rewardToken.balanceOf(addr);
    }

    /**
     * Get umi token balance for contract.
     * @return Return balance of umi token.
     */
    function getStakingBalance() public view returns (uint256) {
        return rewardToken.balanceOf(address(this));
    }


    /**
     * Get nft balance by user address and nft id.
     *
     * @param user The address of user.
     */
    function getNftBalance(address user)
        public
        view
        returns (uint256)
    {
        return nftContract.balanceOf(user);
    }

    /**
     * Get user's nft ids array.
     * @param user The address of user.
     */
    function getUserNftIds(address user)
        public
        view
        returns (uint256[] memory,uint256[] memory, uint256[] memory)
    {
        return (userNftIds[user].ids, userNftIds[user].nftTimes , userNftIds[user].nftPeriodStaking);  //nft period ;
    }

            /**
     * Get length of user's nft id array.
     * @param user The address of user.
     */
    function getUserNftIdsLength(address user) public view returns (uint256) {
        return userNftIds[user].ids.length;
           }



    /**
     * Check if nft id exist.
     * @param user The address of user.
     * @param nftId The nft id of user.
     */
    function isNftIdExist(address user, uint256 nftId)
        public
        view
        returns (bool)
    {
        NftSet storage nftSet = userNftIds[user];
        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        return isIn[nftId];
    }

    /**
     * Set user's nft id.
     *
     * Note: when nft id donot exist, the nft id will be added to ids array, and the idIn flag will be setted true;
     * otherwise do nothing.
     *
     * @param user The address of user.
     * @param nftId The nft id of user.
     */
    function setUserNftIds(address user, uint256 nftId, uint256 stakeTime ,  uint256 period) internal {
        NftSet storage nftSet = userNftIds[user];
        uint256[] storage ids = nftSet.ids;  
        uint256[] storage stakingStartTime = nftSet.nftTimes;
        uint256[] storage stakingPeriod = nftSet.nftPeriodStaking;      


        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        if (!isIn[nftId]) {
            ids.push(nftId);
            stakingStartTime.push(stakeTime);
            stakingPeriod.push(period);
            isIn[nftId] = true;
        }
    }

    /**
     * Remove nft id of user.
     *
     * Note: when user's nft id amount=0, remove it from nft ids array, and set flag=false
     */
    function removeUserNftId(uint256 nftId) internal {
        NftSet storage nftSet = userNftIds[msg.sender];
        uint256[] storage ids = nftSet.ids;
        uint256[] storage stakingStartTime = nftSet.nftTimes;
        uint256[] storage stakingPeriod = nftSet.nftPeriodStaking;

        mapping(uint256 => bool) storage isIn = nftSet.isIn;
        require(ids.length > 0, "remove user nft ids, ids length must > 0");

        // find nftId index
        for (uint256 i = 0; i < ids.length; i++) {
            if (ids[i] == nftId) {
                ids[i] = ids[ids.length - 1];
                stakingStartTime[i] = stakingStartTime[ids.length - 1 ] ;
                stakingPeriod[i] = stakingPeriod[ids.length - 1 ] ;
                isIn[nftId] = false;
                ids.pop();
                stakingStartTime.pop();
                stakingPeriod.pop();


            }
        }
    }

    /**
     * @return Returns current timestamp.
     */
    function _now() internal view returns (uint256) {		
            return block.timestamp;
    }


        // /**
    //  * Get user's total apy.
    //  *
    //  * Note: when umi token staked, base apy will be 12%; otherwise total apy will be 0.
    //  *
    //  * @param user The address of user.
    //  */
    // function getTotalApyOfUser(address user) public view returns (uint256) {
    //     uint256 balanceOfUmi = balances[user];
    //     // if umi balance=0, the apy will be 0
    //     if (balanceOfUmi <= 0) {
    //         return 0;
    //     }
    //     uint256[] memory nftIds = getUserNftIds(user);
    //     // non nft staked, apy will be 12%
    //     if (nftIds.length <= 0) {
    //         return BASE_APY;
    //     }
    //     // totalApy
    //     uint256 totalApy = BASE_APY;
    //     // iter nftIds and calculate total apy
    //     for (uint256 i = 0; i < nftIds.length; i++) {
    //         uint256 nftId = nftIds[i];
    //         // get user balance of nft
    //         uint256 balance = nftBalances[user][nftId];
    //         // get apy of certain nft id
    //         uint256 apy = nftApys[nftId];
    //         totalApy = totalApy.add(balance.mul(apy));
    //     }
    //     return totalApy;
    // }





     function initRewards() internal onlyOwner {
        nftdailyrewards[2]=50;
        nftdailyrewards[60]=50;
        nftdailyrewards[249]=50;
        nftdailyrewards[350]=50;
        nftdailyrewards[366]=50;
        nftdailyrewards[556]=50;
        nftdailyrewards[577]=50;
        nftdailyrewards[584]=50;
        nftdailyrewards[618]=50;
        nftdailyrewards[731]=50;
        nftdailyrewards[793]=50;
        nftdailyrewards[969]=50;
        nftdailyrewards[1443]=50;
        nftdailyrewards[1669]=50;
        nftdailyrewards[1720]=50;
        nftdailyrewards[1858]=50;
        nftdailyrewards[1887]=50;
        nftdailyrewards[2100]=50;
        nftdailyrewards[2527]=50;
        nftdailyrewards[2881]=50;
        nftdailyrewards[3016]=50;
        nftdailyrewards[3323]=50;
        nftdailyrewards[3398]=50;
        nftdailyrewards[3412]=50;
        nftdailyrewards[3446]=50;
        nftdailyrewards[3492]=50;
        nftdailyrewards[3533]=50;
        nftdailyrewards[3552]=50;
        nftdailyrewards[3662]=50;
        nftdailyrewards[3687]=50;
        nftdailyrewards[3735]=50;
        nftdailyrewards[3864]=50;
        nftdailyrewards[3907]=50;
        nftdailyrewards[3925]=50;
        nftdailyrewards[3932]=50;
        nftdailyrewards[4017]=50;
        nftdailyrewards[4085]=50;
        nftdailyrewards[4130]=50;
        nftdailyrewards[4201]=50;
        nftdailyrewards[4404]=50;

    }

}

     