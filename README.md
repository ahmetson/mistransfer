# user-caring - recover your user's nfts and tokens with zero cost

Let's assume that user sent some nft to a wrong smartcontract. There is no way to recover them unless the developer didn't add that functionality.
In other example, what if a user sent the tokens to the address of the token itself? There is no way to return them back.

Due to technical limitations you can't prevent it programmatically. The smartcontracts don't have a way to look to the past transactions.
Simply adding a control to withdraw tokens or nfts is not enough. The owner of the smartcontract has to check the transactions to verify the transfer.

That's why developers aren't building it, as they have to put a lot of effort in recovery without getting anything in back.

**User Caring** is an trustless, automatic user's asset recovery with zero cost or maintain for the developers. 
The only thing for the developers is to extend their smartcontracts from `UserCaring` and pass the recovering contract address:

```solidity
import { UserCaring } from "ahmetson/user-caring/contracts/UserCaring.sol";

contract Sample is UserCaring {
  constructor(address _recoveryAddress) UserCaring(_recoveryAddress) {}
}
```

> **Todo**
>
> An upgradable smartcontracts can support user lock. Later I need to add instructions on how to turn upgradable smartcontract to care about the users.

## Two parts
The package comes with two smartcontracts. 
`UserCaring` is the contract to be used by the developers. This contract adds the control to recover the smartcontracts.

The `MyManager` is the interface for the users. Through this interface users are requesting the token that they sent to a wrong contract.

There are two reasons to have a split smartcontracts.
* First to have a nice user centric UI supported by the community. The developers don't have to run UI to recover the lost data.
* Second, to reduce the smartcontract size from duplicate code.
* And to secure users from price fees so that developers don't change it in the future. The goal is to provide a right balance to recover the price.

### UserInterface
The `UserInterface` is the smartcontract that acts the interface to recover the lost tokens.
The smartcontract's duty is to verify the validness of the transaction hash, and then attempt to recover the lost tokens.

The verification of the transaction is automatic and trustless. The given transaction hash is verified on the multiple public RPC nodes via a Chain Link Oracles.

The `UserInterface` interface:

```solidity
    function recoverMyNft([]byte calldata txHash, address targetContract, address token, uint tokenId) payable external;
    function recoverMyToken([]byte calldata txHash, address targetContract, address token, uint amount) payable external;
    removeUrl([]byte calldata url) external;
    addUrl([]byte calldata url) external;
```

> **Todo**
>
> Add a DAO control for the `removeUrl` and `addUrl` functions.
> 
   

    //
    // in the user-caring page, he puts the transaction hash along with the type of transfer.
    // for testing purpose I put the price in the fixed rate. But later I
    // would add a dynamic price allocation using Chainlink price feeds.
    //
    // now let's assume that user sent some token.
    // If it's a token, then 0.1 point of tokens are transferred to the owner of contract.


   
   
    

### UserCaring
This smartcontract adds a support to return the locked tokens. 
It's indended to be called by a `UserInterface`. 
The latter contract will verify the transaction then it will initiate the recovery.

This smartcontract will have four methods:

```solidity
interface UserCaring {
    function recoverUserNft(address nftAddress, address to, uint tokenId) external; // invoked by the 
    function recoverUserToken(address token, address to, uint amount) external;
    function setCaringSupporter(address newOwner) // change the address that receives the reward.
    function caringSupporter() external returns(address);
}
```

The first two functions are called by the user's interface. Therefore they have a modifier `onlyUserInterface`.
The caring supporter is the address of the smartcontract owner that gets the rewards for caring the users.

#### Preventing Load

Some dapps require the user assets. For example games, bridges or staking contracts may lock the asset.
To prevent recovering them the `UserCaring` provides the functions. Simply put them in the functions that locks/burns:

```solidity
    contract UserCaring {
        constructor() RecoverContract(user_caring_address) {}

        modifier intentionalNftAdd(address nft, address user, uint tokenId) {};
        modifier intentionalNftRemove(address nft, address user, uint tokenId);

        modifier intentionalTokenAdd(address token, address user, uint tokenId) {};
        modifier intentionalTokenRemove(address token, address user, uint tokenId);
    }
```
