# WZI

**Wizzle Infinity token**

Whitepaper: [bit.ly/wziwhitepaper](https://bit.ly/wziwhitepaper)


## Deployment steps


**Order of deployment:**

1. Token

    First deploy the token. You can set up a truffle deployment, use remix or mew.

2. Helper

    After the token, we have to deploy the helper contract.
    This contract serves for two purposes: 
        - Whitelisting of address for presale and crowdsale
        - Airdoping the tokens for users who have registered in presale
    
3. Crowdsale

    Once we have deployed token and contract, we deploy the crowdsale with parameters as specified in constructor.

4. Change crowdsale in token
5. Change global operator in token

6. Mint 50m+ tokens to helper - This is for the airdrop


### Helper Contract
Helper will be selfdestructed after some time.