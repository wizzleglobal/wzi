# WZI

**Wizzle Infinity token**

Whitepaper: [bit.ly/wziwhitepaper](https://bit.ly/wziwhitepaper)

## Key functionalities

1. **WizzleInfinityHelper**
  WZI helper contract is used for whitelisting of addresses and it has a simple function used to airdrop the tokens for registered users. Every user that wants to participate in ICO has to have his address whitelisted. If the address is not whitelisted user cannot interact with Crowdsale.
For purpose of airdrop certain amount of WZI tokens will be sent to this contract.

        /// @dev Whitelist a single address
        /// @param addr Address to be whitelisted
        function whitelist(address addr) public onlyOwner {
        }
    
        /// @dev Remove an address from whitelist
        /// @param addr Address to be removed from whitelist
        function unwhitelist(address addr) public onlyOwner {
        }
    
        /// @dev Whitelist array of addresses
        /// @param arr Array of addresses to be whitelisted
        function bulkWhitelist(address[] arr) public onlyOwner {
        }
    
        /// @dev Check if address is whitelisted
        /// @param addr Address to be checked if it is whitelisted
        /// @return Is address whitelisted?
        function isWhitelisted(address addr) public constant returns (bool) {
        }   
    
        /// @dev Transfer tokens to addresses registered for airdrop
        /// @param dests Array of addresses that have registered for airdrop
        /// @param values Array of token amount for each address that have registered for airdrop
        /// @return Number of transfers
        function airdrop(address[] dests, uint256[] values) public onlyOwner returns (uint256) {
        }

2. **WZI Token**
    WZI token is a ERC20 token with _mint_, _burn_ and _lock_ options. It is controlled by three roles where only a global operator can burn tokens from his address. 
    Locking tokens for certain period of time will amount a new tokens to be minted for the owner of the tokens that have been locked with 1% interest rate at monthly level.
    Claiming a bonus will mint you the bonus for locked tokens.

        /// @dev Pause token transfer
        function pause() public onlyOwner {
        }

        /// @dev Unpause token transfer
        function unpause() public onlyOwner {
        }

        /// @dev Mint new tokens. Owner, Global operator and Crowdsale can mint new tokens and update totalSupply
        /// @param _to Address where the tokens will be minted
        /// @param _amount Amount of tokens to be minted
        /// @return True if successfully minted
        function mint(address _to, uint _amount) public anyRole returns (bool) {
        }

        /// @dev Burns the amount of tokens. Tokens can be only burned from Global operator
        /// @param _amount Amount of tokens to be burned
        /// @return True if successfully burned
        function burn(uint _amount) public onlyGlobalOperator returns (bool) {
        }

        /// @dev Checks the amount of locked tokens
        /// @param _from Address that we wish to check the locked amount
        /// @return Number of locked tokens
        function lockedAmount(address _from) public constant returns (uint256) {
        }

        // token lock
        /// @dev Locking tokens
        /// @param _amount Amount of tokens to be locked
        /// @return True if successfully locked
        function lock(uint _amount) public returns (bool) {
        }

        /// @dev Claim bonus from locked amount
        /// @return True if successful
        function claimBonus() public returns (bool) {
        }

        /// @dev Unlocking the locked amount of tokens
        /// @param _amount Amount of tokens to be unlocked
        /// @return True if successful
        function unlock(uint _amount) public returns (bool) {
        }
        
        /// @dev Transfer tokens
        /// @param _to Address to receive the tokens
        /// @param _value Amount of tokens to be sent
        /// @return True if successful
        function transfer(address _to, uint _value) public returns (bool) {
        }

        /// @dev Check balance of an address
        /// @param _owner Address to be checked
        /// @return Number of tokens
        function balanceOf(address _owner) public constant returns (uint balance) {
        }

        /// @dev Claim tokens that have been sent to contract mistakenly
        /// @param _token Token address that we want to claim
        function claimTokens(address _token) public onlyOwner {
        }

3. **WZI Crowdsale**
WZI Crowdsale contract controls how the tokens are distribuded to users based on certain phases of ICO.
During the presale minimum contribution is 1 ETH.

        /// @dev Fallback function for crowdsale contribution
        function () payable {
            buyTokens(msg.sender);
        }

        /// @dev Buy tokens function
        /// @param beneficiary Address which will receive the tokens
        function buyTokens(address beneficiary) public payable {
        }

        /// @dev Used to change presale time
        /// @param _startTimePre Start time of presale
        /// @param _endTimePre End time of presale
        function changePresaleTimeRange(uint256 _startTimePre, uint256 _endTimePre) public onlyOwner {
        }

        /// @dev Used to change time of ICO
        /// @param _startTimeIco Start time of ICO
        /// @param _endTimeIco End time of ICO
        function changeIcoTimeRange(uint256 _startTimeIco, uint256 _endTimeIco) public onlyOwner {
        }

        /// @dev Change amount of tokens in discount phases
        /// @param _icoDiscountLevel1 Amount of tokens in first phase
        /// @param _icoDiscountLevel2 Amount of tokens in second phase
        function changeDiscountLevels(uint256 _icoDiscountLevel1, uint256 _icoDiscountLevel2) public onlyOwner {
        }

        /// @dev Change discount percentages for different phases
        /// @param _icoDiscountPercentageLevel1 Discount percentage of phase 1
        /// @param _icoDiscountPercentageLevel2 Discount percentage of phase 2
        /// @param _icoDiscountPercentageLevel3 Discount percentage of phase 3
        function changeDiscountPercentages(uint8 _icoDiscountPercentageLevel1, uint8 _icoDiscountPercentageLevel2, uint8 _icoDiscountPercentageLevel3) public onlyOwner {
        }

        /// @dev Check if presale is active
        function isPresale() public constant returns (bool) {
        }

        /// @dev Check if ICO is active
        function isIco() public constant returns (bool) {
        }

        /// @dev Check if presale has ended
        function hasPresaleEnded() public constant returns (bool) {
        }

        /// @dev Check if ICO has ended
        function hasIcoEnded() public constant returns (bool) {
        }

        /// @dev Function to extract mistakenly sent ERC20 tokens sent to Crowdsale contract
        /// @param _token Address of token we want to extract
        function claimTokens(address _token) public onlyOwner {
        }

## Deployment steps


**Order of deployment:**

1. Token

2. Helper
    
3. Crowdsale

4. Change crowdsale in token

5. Change global operator in token

6. Mint 50m+ tokens to helper - This is for the airdrop


### Helper Contract
Helper will be selfdestructed after some time.