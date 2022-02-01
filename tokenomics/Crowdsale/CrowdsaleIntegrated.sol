//SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import"@openzeppelin/contracts/utils/math/SafeMath.sol";
import"@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Crowdsale is Ownable  {
    
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    // The token being sold
    IERC20 immutable public _token;

    // Address where funds are collected
    address payable public _wallet;

    // How many token units a buyer gets per wei.
 
    uint256 public _rate;

    // Amount of wei raised
    uint256 private _weiRaised;
    
    // Opening and closing time
    uint256 public openingTime;
    uint256 public closingTime;

    //cap for crowdsale
    uint256 public _maxCap;

    //tokens per clients
    mapping(address => uint256) internal _contributions;

    /**
     * Event for token purchase logging
     * @param purchaser who paid for the tokens
     * @param beneficiary who got the tokens
     * @param value weis paid for purchase
     * @param amount amount of tokens purchased
     */
    event TokensPurchased(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

    constructor (uint256 rate, address payable wallet, IERC20 token, uint256 _openingTime, uint256 _closingTime, uint256 _cap)  {
        require(rate > 0, "Crowdsale: rate is 0");
        require(wallet != address(0), "Crowdsale: wallet is the zero address");
        require(address(token) != address(0), "Crowdsale: token is the zero address");
        require(_openingTime >= block.timestamp, "time is greater than opening time");
        require(_closingTime >= _openingTime, "closingTime should be lesss than openingtime");
        require(_cap > 0);
        
        _rate = rate;
        _wallet = wallet;
        _token = token;
        openingTime = _openingTime;
        closingTime = _closingTime;
        _maxCap = _cap;
    }

 
    fallback () external payable {
        buyTokens(msg.sender);
    }
    
    receive() external payable
    {
        buyTokens(msg.sender);
    }

        /**
     * @dev Returns the cap of a specific beneficiary.
     * @return Current cap for individual beneficiary
     */
    function getCap() public view returns (uint256) {
        return _maxCap;
    }
      /**
     * @dev set cap of a specific beneficiary.
     */
        function SetCap(uint256 new_cap) public onlyOwner   {
        _maxCap =new_cap;
    }

    /**
     * @dev Returns the amount contributed so far by a specific beneficiary.
     * @param beneficiary Address of contributor
     * @return Beneficiary contribution so far
     */
    function getUserContribution(address beneficiary)
        public
        view
        returns (uint256)
    {
        return _contributions[beneficiary];
    }


    /**
     * @return the token being sold.
     */
    function token() public view returns (IERC20) {
        return _token;
    }

    /**
     * @return the address where funds are collected.
     */
    function wallet() public view returns (address payable) {
        return _wallet;
    }

    /**
     * @return the number of token units a buyer gets per wei.
     */
    function GetRate() public view returns (uint256) {
        return _rate;
    }

       /**
     * @dev set new rate .
     */
    function SetRate(uint256 new_rate) public onlyOwner {
        _rate =new_rate;
    }

       /**
     * @dev set new Opening,closing time .
     */

    function SetOpeningTime(uint256 new_openingTime) public onlyOwner {
        openingTime =new_openingTime;
    }

    function SetClosingTime(uint256 new_closingTime) public onlyOwner {
        closingTime =new_closingTime;
    }


    /**
     * @return the amount of wei raised.
     */
    function weiRaised() public view returns (uint256) {
        return _weiRaised;
    }

     modifier onlyWhileOpen {
    // solium-disable-next-line security/no-block-members
    require(block.timestamp >= openingTime && block.timestamp <= closingTime, "crowdsale is closed");
    _;
     }

    function buyTokens(address beneficiary) public payable {
        uint256 weiAmount = msg.value;
 
        _preValidatePurchase(beneficiary, weiAmount);

        // calculate token amount to be created
        uint256 tokens = _getTokenAmount(weiAmount);
        
        // update state
        _weiRaised = _weiRaised.add(weiAmount);

        _processPurchase(beneficiary, tokens);
        emit TokensPurchased(msg.sender, beneficiary, weiAmount, tokens);

        _updatePurchasingState(beneficiary, weiAmount);

        _forwardFunds();
        _postValidatePurchase(beneficiary, weiAmount);
    }

    /**
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _preValidatePurchase(address beneficiary, uint256 weiAmount) internal virtual onlyWhileOpen {
        require(beneficiary != address(0), "Crowdsale: beneficiary is the zero address");
        require(weiAmount != 0, "Crowdsale: weiAmount is 0");
                require(
            _contributions[beneficiary].add(weiAmount) <= _maxCap,
            "IndividuallyCappedCrowdsale: beneficiary's cap exceeded"
        );


        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
    }

    /**
     * @dev Validation of an executed purchase. Observe state and use revert statements to undo rollback when valid
     * conditions are not met.
     * @param beneficiary Address performing the token purchase
     * @param weiAmount Value in wei involved in the purchase
     */
    function _postValidatePurchase(address beneficiary, uint256 weiAmount) internal view {
        // solhint-disable-previous-line no-empty-blocks
    }

    /**
     * @dev Source of tokens. Override this method to modify the way in which the crowdsale ultimately gets and sends
     * its tokens.
     * @param beneficiary Address performing the token purchase
     * @param tokenAmount Number of tokens to be emitted
     */
    function _deliverTokens(address beneficiary, uint256 tokenAmount) internal {
        _token.safeTransfer(beneficiary, tokenAmount);
    }

    /**
     * @dev Executed when a purchase has been validated and is ready to be executed. Doesn't necessarily emit/send
     * tokens.
     * @param beneficiary Address receiving the tokens
     * @param tokenAmount Number of tokens to be purchased
     */
    function _processPurchase(address beneficiary, uint256 tokenAmount) internal {
        _deliverTokens(beneficiary, tokenAmount);
    }

    /**
     * @dev Override for extensions that require an internal state to check for validity (current user contributions,
     * etc.)
     * @param beneficiary Address receiving the tokens
     * @param weiAmount Value in wei involved in the purchase
     */
    function _updatePurchasingState(address beneficiary, uint256 weiAmount) internal {
                  _contributions[beneficiary] = _contributions[beneficiary].add(
            weiAmount);
    }

    /**
     * @dev Override to extend the way in which ether is converted to tokens.
     * @param weiAmount Value in wei to be converted into tokens
     * @return Number of tokens that can be purchased with the specified _weiAmount
     */
    function _getTokenAmount(uint256 weiAmount) internal view returns (uint256) {
        return weiAmount.mul(_rate); 
    }

      /**
     * @return Number of tokens left in contract
     */

    function balanceContract() public view returns (uint256) {
        return _token.balanceOf(address(this));
    }


    /**
     * @dev Determines how ETH is stored/forwarded on purchases.
     */
    function _forwardFunds() internal {
        _wallet.transfer(msg.value);
    }
}