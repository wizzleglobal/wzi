pragma solidity ^0.4.18;

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

contract Mortal is Ownable {
    function kill() onlyOwner {
        selfdestruct(owner);
    }
}

contract WizzleGlobalTokenWhitelist is Mortal {
    mapping (address => bool) whitelist;

    function add(address addr) public onlyOwner {
        require(!whitelist[addr]);
        whitelist[addr] = true;
    }

    function remove(address addr) public onlyOwner {
        require(whitelist[addr]);
        whitelist[addr] = false;
    }

    function bulkAdd(address[] arr) public onlyOwner {
        for (uint i = 0; i < arr.length; i++) {
            address addr = arr[i];
            whitelist[addr] = true;
        }
    }

    function isWhitelisted(address addr) public constant returns (bool) {
        return whitelist[addr];
    }    

}