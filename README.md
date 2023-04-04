# Lockdrop

The lockdrop smart contracts enables users to lock a stablecoin for a specific duration in exchange for shares in a campaign that drops $GOAL3 tokens. The contract has a referral program for earning bonus shares. It includes structs for Plans and Campaigns with relevant parameters and mappings, as well as functions for locking, claiming, and checking balances. The contract uses the Upgradeable, IERC20, IVesting, and IReferral interfaces and OpenZeppelin's SignatureChecker library.

# Lockdrop Referral

The Referral smart contract manages referral campaigns, with functions for creating and updating campaigns, checking if users have a referrer, getting a referee's referrer, and checking campaign status. It includes functions for returning bonus rates based on campaign ID and current amount, and a boosted rate based on referrer address.

# $zkUSD

zkUSD is an ERC-20 token written in Solidity with added features for vesting and access control. It includes two new roles for token minting and burning, a variable for pausing token transfers, and an interface for a separate vesting contract. The contract overrides transfer functions to manage vesting schedules, and has several getter and setter functions for modifying contract state. It also includes functions for minting, burning, and placing tokens on hold for a specific address.

# Upgradable

The code is a smart contract called Upgradeable that provides a framework for upgrading the implementation of a smart contract. It inherits from the Initializable, UUPSUpgradeable, and OwnableUpgradeable contracts from the OpenZeppelin library. The contract's constructor disables the contract from being initialized more than once. Additionally, the contract overrides the _authorizeUpgrade function to ensure that only the owner can authorize the upgrade of the contract implementation.

# Vesting

This is an implementation of a vesting contract that allows for locking and releasing tokens according to a defined vesting plan. The use of structs to define the plans and volumes makes the code more organized and easier to read.

The createVesting() function handles the creation of new vesting plans and the transfer of tokens to the user. The getAmountLock() and getAmountLockBySpender() functions accurately calculate the locked token amounts, taking into account rollover values and excluded spenders.

The transfer() function updates the used volume for the sender and releases the locked tokens for the receiver according to the vesting plan. The use of the _getAmountLock() function for each plan makes the code modular and easier to maintain.

Overall, this contract is a good example of how to implement a vesting contract in Solidity.
