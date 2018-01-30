pragma solidity ^0.4.18;

library SafeMath {
  function mul(uint a, uint b) internal constant returns (uint) {
    uint c = a * b;
    assert(a == 0 || c / a == b);
    return c;
  }
  function div(uint a, uint b) internal constant returns (uint) {
    uint c = a / b;
    return c;
  }
  function sub(uint a, uint b) internal constant returns (uint) {
    assert(b <= a);
    return a - b;
  }
  function add(uint a, uint b) internal constant returns (uint) {
    uint c = a + b;
    assert(c >= a);
    return c;
  }
}

/// @title Roles contract
contract Roles {
  // address of owner - all priviledges
  address public owner;

  // global operator address
  address public globalOperator;

  // crowdsale address
  address public crowdsale;
  
  function Roles() public {
    owner = msg.sender;
    globalOperator = address(0); // initially
    crowdsale = address(0); //  initially
  }

  // modifier to enforce only owner function access
  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }

  // modifier to enforce only global operator function access
  modifier onlyGlobalOperator() {
    require(msg.sender == globalOperator);
    _;
  }

  // modifier to enforce any of 3 specified roles to access function
  modifier anyRole() {
    require(msg.sender == owner || msg.sender == globalOperator || msg.sender == crowdsale);
    _;
  }

  // owner can set new owner
  function changeOwner(address newOwner) onlyOwner public {
    require(newOwner != address(0));
    OwnerChanged(owner, newOwner);
    owner = newOwner;
  }

  // owner can set new global operator
  function changeGlobalOperator(address newGlobalOperator) onlyOwner public {
    require(newGlobalOperator != address(0));
    GlobalOperatorChanged(globalOperator, newGlobalOperator);
    globalOperator = newGlobalOperator;
  }

  // owner can set new crowdsale
  function changeCrowdsale(address newCrowdsale) onlyOwner public {
    require(newCrowdsale != address(0));
    CrowdsaleChanged(crowdsale, newCrowdsale);
    crowdsale = newCrowdsale;
  }

   //events
  event OwnerChanged(address indexed _previousOwner, address indexed _newOwner);
  event GlobalOperatorChanged(address indexed _previousGlobalOperator, address indexed _newGlobalOperator);
  event CrowdsaleChanged(address indexed _previousCrowdsale, address indexed _newCrowdsale);

}

/// @title ERC20 contract
contract ERC20 {
  uint public totalSupply;
  function balanceOf(address who) public constant returns (uint);
  function transfer(address to, uint value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint value);
  
  function allowance(address owner, address spender) public constant returns (uint);
  function transferFrom(address from, address to, uint value) public returns (bool);
  function approve(address spender, uint value) public returns (bool);
  event Approval(address indexed owner, address indexed spender, uint value);
}

/// @title ExtendedToken contract
contract ExtendedToken is ERC20, Roles {
  using SafeMath for uint;

  // max amount of minted tokens (6 billion tokens)
  uint256 public constant mintCap = 6 * 10**27;

  // minimum amount to lock (100 000 tokens)
  uint public constant minimumLockAmount = 100000 * 10**18;

  // structure that describes locking of tokens
  struct Locked {
      uint lockedAmount; // amount of tokens locked
      uint lastUpdated; // time when tokens were last locked
      uint lastClaimed; // time when bonus was last claimed
  }
  
  // used to pause the transfer
  bool public transferPaused = false;

  // mappings for balances, locked amounts and allowance
  mapping (address => uint) balances;
  mapping (address => Locked) locked;
  mapping (address => mapping (address => uint)) internal allowed;

  // pause transfer
  function pause() public onlyOwner {
      transferPaused = true;
      Pause();
  }

  // unpause transfer
  function unpause() public onlyOwner {
      transferPaused = false;
      Unpause();
  }

  // check number of locked tokens
  function lockedAmount(address _from) public constant returns (uint256) {
      return locked[_from].lockedAmount;
  }

  // token lock
  function lock(uint _amount) public returns (bool) {
      require(msg.sender != address(0));
      require(_amount >= minimumLockAmount);
      uint newLockedAmount = locked[msg.sender].lockedAmount.add(_amount);
      require(balances[msg.sender] >= newLockedAmount);
      _checkLock(msg.sender);
      locked[msg.sender].lockedAmount = newLockedAmount;
      locked[msg.sender].lastUpdated = now;
      Lock(msg.sender, _amount);
      return true;
  }

  // TODO: Maybe implement this in claimBonus() function fully
  function _checkLock(address _from) internal returns (bool) {

    /*
      if (locked[_from].lockedAmount != 0) {
        if (locked[_from].lastUpdated + 30 days >= now) {
            uint _value = locked[_from].lockedAmount.div(100);
            totalSupply = totalSupply.add(_value);
            balances[_from] = balances[_from].add(_value);
            locked[_from].lastClaimed = now;
            LockClaimed(_from, _value);
            return true;
        }
        return false;
      }
      return false;
    */

    if (locked[_from].lockedAmount >= minimumLockAmount) { // or "> 0" ???
      uint referentTime = max(locked[_from].lastUpdated, locked[_from].lastClaimed);
      uint timeDifference = now.sub(referentTime);
      uint amountTemp = (locked[_from].lockedAmount.mul(timeDifference)).div(30 days); 
      uint mintableAmount = amountTemp.div(100);
      //uint mintPercentage = now.sub(referentTime).div(30 days);
      //uint mintableAmount = (locked[_from].lockedAmount.mul(mintPercentage)).div(100);

      locked[_from].lastClaimed = now;
      _mint(_from, mintableAmount);
      LockClaimed(_from, mintableAmount);
      return true;
    }
    //else {
    //  locked[_from].lastUpdated = now;
    //}
    return false;
  }

  // function for claiming bonus -> maybe better claimLock()...
  function claimBonus() public returns (bool) {
      require(msg.sender != address(0));
      return _checkLock(msg.sender);
  }

  // unlock the tokens
  function unlock(uint _amount) public returns (bool) {
      require(msg.sender != address(0));
      require(locked[msg.sender].lockedAmount >= _amount);
      uint newLockedAmount = locked[msg.sender].lockedAmount.sub(_amount);
      if (newLockedAmount < minimumLockAmount) {
        balances[msg.sender] = balances[msg.sender].add(locked[msg.sender].lockedAmount);
        Unlock(msg.sender, locked[msg.sender].lockedAmount);
        locked[msg.sender].lockedAmount = 0;
      } else {
        balances[msg.sender] = balances[msg.sender].add(newLockedAmount);
        locked[msg.sender].lockedAmount = newLockedAmount;
        Unlock(msg.sender, _amount);
      }
      return true;
  }

   // owner, global operator and crowdsale can mint new tokens and update totalSupply
  function mint(address _to, uint _amount) public anyRole returns (bool) {
      _mint(_to, _amount);
      Mint(_to, _amount);
      return true;
  }
  
  // internal mint with checks
  function _mint(address _to, uint _amount) internal returns (bool) {
      require(_to != address(0));
	    require(totalSupply.add(_amount) <= mintCap);
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      return true;
  }

  // only global operator can burn tokens from his own address
  function burn(uint _amount) public onlyGlobalOperator returns (bool) {
	    uint256 newBalance = balances[msg.sender].sub(_amount);
	    require(newBalance >= 0);
      balances[msg.sender] = newBalance;
      totalSupply = totalSupply.sub(_amount);
      Burn(msg.sender, _amount);
      return true;
  }

  // ERC20 compliant transfer function
  function transfer(address _to, uint _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
  }

  // internal function for WZI token transfer
  function _transfer(address _from, address _to, uint _value) internal {
    require(!transferPaused);
    require(_to != address(0));
    require(balances[_from] >= _value.add(locked[_from].lockedAmount));
    require(balances[_to].add(_value) >= balances[_to]);    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  
  function transferFrom(address _from, address _to, uint _value) public returns (bool) {
    allowed[_from][msg.sender] = allowed[_from][msg.sender].sub(_value);
    _transfer(_from, _to, _value);
    return true;
  }

  function balanceOf(address _owner) public constant returns (uint balance) {
    return balances[_owner];
  }

  function approve(address _spender, uint _value) public returns (bool) {
    allowed[msg.sender][_spender] = _value;
    Approval(msg.sender, _spender, _value);
    return true;
  }

  function allowance(address _owner, address _spender) public constant returns (uint remaining) {
    return allowed[_owner][_spender];
  }

  function increaseApproval (address _spender, uint _addedValue) public returns (bool success) {
    allowed[msg.sender][_spender] = allowed[msg.sender][_spender].add(_addedValue);
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  function decreaseApproval (address _spender, uint _subtractedValue) public returns (bool success) {
    uint oldValue = allowed[msg.sender][_spender];
    if (_subtractedValue > oldValue) {
      allowed[msg.sender][_spender] = 0;
    } else {
      allowed[msg.sender][_spender] = oldValue.sub(_subtractedValue);
    }
    Approval(msg.sender, _spender, allowed[msg.sender][_spender]);
    return true;
  }

  // utility max function
  function max(uint256 a, uint256 b) pure internal returns (uint256) {
    return (a > b) ? a : b;
  }

  // don't accept ether
  function () public payable {
    revert();
  }

  // claim mistakenly sent tokens to this contract including ether
  function claimTokens(address _token) public onlyOwner {
    if (_token == address(0)) {
         owner.transfer(this.balance);
         return;
    }

    ERC20 token = ERC20(_token);
    uint balance = token.balanceOf(this);
    token.transfer(owner, balance);
    ClaimedTokens(_token, owner, balance);
  }

  // events
  event Mint(address _to, uint _amount);
  event Burn(address _from, uint _amount);
  event Lock(address _from, uint _amount);
  event LockClaimed(address _from, uint _amount);
  event Unlock(address _from, uint _amount);
  event ClaimedTokens(address indexed _token, address indexed _owner, uint _amount);
  event Pause();
  event Unpause();

}

/// @title WizzleInfinityToken contract
contract WizzleInfinityToken is ExtendedToken {
    string public constant name = "Wizzle Infinity Token";
    string public constant symbol = "WZI";
    uint8 public constant decimals = 18;
    string public constant version = "v1";

    function WizzleInfinityToken() public { 
      totalSupply = 0;
    }

}