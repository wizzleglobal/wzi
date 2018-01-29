pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }

  function div(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a / b;
    return c;
  }

  function sub(uint256 a, uint256 b) internal constant returns (uint256) {
    assert(b <= a);
    return a - b;
  }

  function add(uint256 a, uint256 b) internal constant returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
}

contract Ownable {
  
  address public owner;
  event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

  function Ownable() public {
    owner = msg.sender;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  function transferOwnership(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnershipTransferred(owner, newOwner);
    owner = newOwner;
    }

}

contract Token {
  function mint(address _to, uint _amount) public returns (bool);
}

contract Whitelist {
  function isWhitelisted(address addr) public constant returns (bool);
}

contract Crowdsale is Ownable {
  using SafeMath for uint256;
  
  // token reference
  Token public token;
  // whitelist reference
  Whitelist public whitelist;
  // presale time range (inclusive)
  uint256 public startTimePre;
  uint256 public endTimePre;
  // ICO time range (inclusive)
  uint256 public startTimeIco;
  uint256 public endTimeIco;
  // address where funds are collected
  address public wallet;
  // how many token units a buyer gets per wei
  uint32 public rate;
  // amount of tokens sold in presale
  uint256 public tokensSoldPre;
  // amount of tokens sold in ICO
  uint256 public tokensSoldIco;
  // amount of raised money in wei
  uint256 public weiRaised;
  // number of contributors
  uint256 public contributors;
  
  // purchaser - who paid for the tokens
  // beneficiary - who got the tokens
  // value - weis paid for purchase
  // amount - amount of tokens purchased
  event TokenPurchase(address indexed purchaser, address indexed beneficiary, uint256 value, uint256 amount);

  function Crowdsale(uint256 _startTimePre, uint256 _endTimePre, uint256 _startTimeIco, uint256 _endTimeIco, uint32 _rate, address _wallet, address _tokenAddress) {
    // startTimePre < endTimePre < startTimeIco < endTimeIco
    require(_startTimePre >= now);
    require(_endTimePre >= _startTimePre);
    require(_startTimeIco >= _endTimePre);
    require(_endTimeIco >= _startTimeIco);
    require(_rate > 0);
    require(_wallet != address(0));
    require(_tokenAddress != address(0));
    startTimePre = _startTimePre;
    endTimePre = _endTimePre;
    startTimeIco = _startTimeIco;
    endTimeIco = _endTimeIco;
    rate = _rate;
    wallet = _wallet;
    token = Token(_tokenAddress);
  }

  function setRate(uint32 _rate) public onlyOwner {
    require(_rate > 0);
    rate = _rate;
  }

  function () payable {
    buyTokens(msg.sender);
  }

  function buyTokens(address beneficiary) public payable {
    require(beneficiary != address(0));
    //here whitelisting check
    require(whitelist.isWhitelisted(beneficiary));
    uint256 weiAmount = msg.value;
    require(weiAmount > 0);
    uint256 tokenAmount = 0;
    if (isPresale()) {
      require(weiAmount >= 1 ether);
      tokenAmount = getTokenAmount(weiAmount, 50);
      uint256 newTokensSoldPre = tokensSoldPre.add(tokenAmount);
      require(newTokensSoldPre <= 1500 * 10**6 * 10**18);
      tokensSoldPre = newTokensSoldPre;
    } else if (isIco()) {
      uint8 discountPercentage = getIcoDiscountPercentage();
      tokenAmount = getTokenAmount(weiAmount, discountPercentage);
      tokensSoldIco = tokensSoldIco.add(tokenAmount);
    } else {
      // stop execution and return remaining gas
      require(false);
    }
    executeTransaction(beneficiary, weiAmount, tokenAmount);
  }

  function getIcoDiscountPercentage() internal constant returns (uint8) {
    uint256 discountLevel1 = 500 * 10**6 * 10**18;
    uint256 discountLevel2 = 500 * 10**6 * 10**18;
    if (tokensSoldIco <= discountLevel1) {
      return 40;
    } else if (tokensSoldIco <= discountLevel1 + discountLevel2) {
      return 30;
    } else { 
      return 25;
    }
  }

  function getTokenAmount(uint256 weiAmount, uint8 discountPercentage) internal constant returns (uint256) {
    require(discountPercentage >= 0 && discountPercentage <= 100);
    uint256 baseTokenAmount = weiAmount.mul(rate);
    uint256 tokenAmount = baseTokenAmount.mul(10000).div(100 - discountPercentage);
    return tokenAmount;
  }

  function executeTransaction(address beneficiary, uint256 weiAmount, uint256 tokenAmount) internal {
    weiRaised = weiRaised.add(weiAmount);
    token.mint(beneficiary, tokenAmount);
    TokenPurchase(msg.sender, beneficiary, weiAmount, tokenAmount);
	  contributors = contributors.add(1);
    wallet.transfer(weiAmount);
  }

  function isPresale() public constant returns (bool) {
    return now >= startTimePre && now <= endTimePre;
  }

  function isIco() public constant returns (bool) {
    return now >= startTimeIco && now <= endTimeIco;
  }

  // true if presale event has ended
  function hasPresaleEnded() public constant returns (bool) {
    return now > endTimePre;
  }

  // true if ICO event has ended
  function hasIcoEnded() public constant returns (bool) {
    return now > endTimeIco;
  }

  // tokens sold in both presale and ICO
  function cummulativeTokensSold() public constant returns (uint256) {
    return tokensSoldPre + tokensSoldIco;
  }

}

contract WizzleInfinityTokenCrowdsale is Crowdsale {
  function WizzleInfinityTokenCrowdsale(uint256 _startTime, uint256 _endTime, uint256 _rate, address _wallet, address _tokenAddress)
    Crowdsale(_startTime, _endTime, _rate, _wallet, _tokenAddress) 
    {
    }

}