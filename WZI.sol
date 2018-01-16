pragma solidity ^0.4.18;

import 'Ownable.sol';

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

contract StandardToken is ERC20, Ownable {
  using SafeMath for uint;

  // events
  event Mint(address _to, uint _amount);
  event Burn(address _from, uint _amount);
  event Lock(address _from, uint _amount);
  event LockClaimed(address _from, uint _amount);
  event Unlock(address _from, uint _amount);
  event Pause();
  event Unpause();

  struct Locked {
      uint lockedAmount;
      uint lastUpdated; // time when tokens were last locked
      uint lastClaimed; // time when bonus was last claimed 
  }
  
  // used to pause the transfer
  bool public transferPaused = false;
  // minimum amount to lock
  uint public constant MIN_LOCK_AMOUNT = 100000;   

  mapping (address => uint) balances;
  mapping (address => Locked) locked;
  mapping (address => mapping (address => uint)) internal allowed;
  
  // don't accept ETH
  function () public payable {
    revert();
  }

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

  
  function mint(address _to, uint _amount) public onlyOwner returns (bool) {
      _mint(_to, _amount);
      Mint(_to, _amount);
      return true;
  }
  
  // mint new tokens and update totalSupply
  function _mint(address _to, uint _amount) internal returns (bool) {
      require(_to != address(0));
      totalSupply = totalSupply.add(_amount);
      balances[_to] = balances[_to].add(_amount);
      return true;
  }

  // burn the tokens from address 
  // TODO: this is just a simple implementation; still need to see how 
  // will the tokens be burned, ie how are we going to call this function?
  function burn(address _from, uint _amount) public onlyOwner returns (bool) {
      require(_from != address(0));
      balances[_from] = balances[_from].sub(_amount);
      totalSupply = totalSupply.sub(_amount);
      Burn(_from, _amount);
      return true;
  }

  // token lock
  function lock(uint _amount) public returns (bool) {
      require(msg.sender != address(0));
      require(_amount >= MIN_LOCK_AMOUNT);
      uint newLockedAmount = locked[msg.sender].lockedAmount.add(_amount);
      require(balances[msg.sender] >= newLockedAmount);
      _checkLock(msg.sender);
      locked[msg.sender].lockedAmount = newLockedAmount;
      locked[msg.sender].lastUpdated = now;
      Lock(msg.sender, _amount);
      return true;
  }

  function max(uint a, uint b) internal pure returns(uint) {
    return (a > b) ? a : b;
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

    if (locked[_from].lockedAmount >= MIN_LOCK_AMOUNT) { // or "> 0" ???
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
      if (newLockedAmount < MIN_LOCK_AMOUNT) {
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

  function _transfer(address _from, address _to, uint _value) internal {
    require(!transferPaused);
    require(_to != address(0));
    require(balances[_from] >= _value.add(locked[_from].lockedAmount));
    require(balances[_to].add(_value) >= balances[_to]);    
    balances[_from] = balances[_from].sub(_value);
    balances[_to] = balances[_to].add(_value);
    Transfer(_from, _to, _value);
  }
  
  function transfer(address _to, uint _value) public returns (bool) {
    _transfer(msg.sender, _to, _value);
    return true;
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

  // owner can transfer out any accidentally sent ERC20 tokens  
  function transferAnyERC20Token(address tokenAddress, uint _amount) public onlyOwner returns (bool success) {
      return ERC20(tokenAddress).transfer(owner, _amount);
  }

}

contract WizzleInfinityToken is StandardToken {
    string public constant name = "Wizzle Infinity Token";
    string public constant symbol = "WZI";
    uint8 public constant decimals = 0;
    function WizzleInfinityToken() public { 
        totalSupply = 0;
    }
}