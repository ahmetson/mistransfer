# Zero deployment cost recovery of lost crypto


📄 Clone or fork `mistransfer`:

```sh
git clone https://github.com/ahmetson/mistransfer.git
```

Sometimes, we accidentally send our crypto assets to the wrong address. I, for example, sent the tokens to the token address itself.

While it's impossible to return the assets from the wallet addresses, it is possible to prevent losing funds that are sent to the smartcontracts.

The smartcontract developers need two things to help the users.
First, a smartcontract must have a function that returns the NFTs/Tokens.
Second, a developer must verify the user address by looking at the transactions.

The first part of the solution is solved easily by adding a simple function.
However, the second part of the solution is problematic. It needs special and unfeasible customer service. This support system must receive the user's requests, verify them on the transaction, and then trigger the function on the smartcontract. It all costs unnecessary time and money.

But what if we had an automatic, zero-cost for developers solution?

**User Caring** is a trust-less,  njautomatic user's asset recovery with zero cost or maintenance for the developers.
The only thing for the developers is to extend their smartcontracts from `UserCaring` and pass the recovering contract address:

```solidity
import { UserCaring } from "ahmetson/user-caring/contracts/UserCaring.sol";

contract Sample is UserCaring {
  constructor(address _userInterface) UserCaring(_userInterface) {}
}
```

> **Todo**
>
> An upgradable smartcontracts can support user lock. Later, I need to add instructions on how to turn up an upgraded smart contract to care about the users.

## Two parts
The package comes with two smartcontracts.
`UserCaring` is the contract to be used by the developers. This contract adds the control to recover the smartcontracts.

The `MyManager` is the interface for the users. Through this interface, users request the token they sent to the wrong contract.

There are two reasons to have split smartcontracts.
* First, to have a nice user-centric UI supported by the community. The developers don't have to run UI to recover the lost data.
* Second, to reduce the smartcontract size from duplicate code.
* And to secure users from price fees so that developers don't change it in the future. The goal is to provide a proper balance to recover the price.

### UserInterface
The `UserInterface` is the smartcontract that acts as the interface to recover the lost tokens.
The smart contract must verify the validity of the transaction hash and then attempt to recover the lost tokens.

The verification of the transaction is automatic and trustless. The given transaction hash is verified on the multiple public RPC nodes via Chain Link Oracles.

The `UserInterface` interface:

```solidity
interface UserInterface {
    function recoverMyNft(byte[] call data txHash, address targetContract, address token, uint tokenId) payable external;
    function recoverMyToken(byte[] call data txHash, address targetContract, address token, uint amount) payable external;
    function removeUrl(byte[] call data URL) external;
    function addUrl(byte[] calldata url) external;
}
```

> **Todo**
>
> Add a DAO control for the `removeUrl` and `addUrl` functions.
>


    //
    //In the user-caring page, he puts the transaction hash along with the type of transfer.
    //I put the price in the fixed rate for testing purposes. But later I
    // would add a dynamic price allocation using Chainlink price feeds.
    //
    //Now, let's assume that the user sent some token.
    // If it's a token, then 0.1 points of tokens are transferred to the owner of the contract.


### UserCaring
This smartcontract adds support to return the locked tokens.
It's intended to be called a `UserInterface`.
The latter contract will verify the transaction, and then it will initiate the recovery.

This smartcontract will have four methods:

```solidity
interface UserCaring {
    function recoverUserNft(address not address, address to, uint tokenId) external; // invoked by the 
    function recoverUserToken(address token, address to, uint amount) external;
    function setCaringSupporter(address newOwner) external; // change the address that receives the reward.
    function caringSupporter() external returns(address);
}
```

The first two functions are called by the user's interface. Therefore, they have a modifier `only user interface.`
The caring supporter is the address of the smartcontract owner who gets the rewards for caring for the users.

#### Preventing Load

Some dapps require the user assets. For example, games, bridges, or staking contracts may lock the asset.
To prevent recovering them, the `UserCaring` provides the functions. Put them in the functions that lock/burn:

```solidity
    contract UserCaring {
        constructor(address user-interface) UserCaring(user-interface) {}

        modifier intentionalNftAdd(address nft, address user, uint tokenId) {};
        modifier intentionalNftRemove(address nft, address user, uint tokenId);

        modifier intentionalTokenAdd(address token, address user, uint tokenId) {};
        modifier intentionalTokenRemove(address token, address user, uint tokenId);
    }
```

---

# Usage

Download the user interface as a submodule.
Create `.env` from `.env.example`.

Compile the smartcontracts:

```shell
npx hardhat compile
```

Once compiled, export the abi.

```shell
npx hardhat export-abi
```