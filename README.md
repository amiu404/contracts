# Lockdrop
This is a smart contract written in Solidity. The contract is a lockdrop contract that allows users to lock a stablecoin for a specific duration in exchange for a certain amount of shares in a campaign. The shares can later be exchanged for a token that is being dropped by the campaign. The contract also has a referral program where referrers can earn additional shares for their referrals.

The contract has a struct called "Plan" which contains the minimum and maximum amount of stablecoin that can be locked, the lock duration, the vesting duration, the drop rate, and the boosted rate. There is also a struct called "Campaign" which contains the start and end time of the campaign, the duration of the drop vesting, the campaign status, the total drop amount, and other mappings related to the campaign.

The contract also has a struct called "CampaignData" which contains the total amount of stablecoin locked, the total number of shares, and other mappings related to the users who have participated in the campaign.

The contract has functions for initializing the contract, locking stablecoin and earning shares, claiming the dropped token, and checking the amount of stablecoin locked and the amount of the dropped token claimed by a user. The contract also has a function for checking the referrer of a user and calculating the bonus shares for the referrer.

The contract uses other contracts such as the "Upgradeable" contract, the "IERC20" interface, the "IVesting" interface, and the "IReferral" interface. The contract also uses the "SignatureChecker" library from the OpenZeppelin library for checking the signature of an address.
# Lockdrop Referral
This is a smart contract written in Solidity. Here's a brief explanation of what it does:

The contract is called Referral and it manages referral campaigns. Referral campaigns are created by calling the createCampaign function, passing in various parameters such as bonus amounts, bonus rates, and whether or not referrals are required. Referral campaigns can also be updated by calling the setBoostedRateByReferrers, setBonusRates, and setWhitelisted functions.

Users can check if they have a referrer by calling the checkReferrer function, which takes in a campaign ID, a referee address, a referrer address, and a referrer volume. If the referee is already whitelisted, the function will return address(0). If the referee already has a referrer, the function will return the current referrer's address. Otherwise, the function will require that the referrer is not address(0) and that the referrer volume is greater than 0. If these conditions are met, the function will update the referrer and return the referrer's address.

Users can get the referrer of a given referee by calling the getReferrer function, passing in the campaign ID and the referee address.

Users can also check if a campaign is enabled, required, or if an account is whitelisted by calling the isEnabled, isRequired, and isWhitelisted functions, respectively.

Finally, there are two functions that return bonus rates: bonusRate and boostedRate. The bonusRate function takes in a campaign ID and a current amount, and returns the bonus rate for that amount. The boostedRate function takes in a campaign ID and a referrer address, and returns the boosted rate for that referrer.

#$zkUSD
This is a Solidity smart contract that implements an ERC20 token with additional functionality for vesting and access control. The contract inherits from the OpenZeppelin ERC20Upgradeable and AccessControlUpgradeable contracts.

The contract defines two new roles for minting and burning tokens called MINTER_ROLE and BURNER_ROLE, respectively. It also has a new state variable called isPaused, which can be used to pause token transfers in certain situations.

The contract also has a vestingContract variable of type IVestingContract, which is an interface for a separate contract that manages vesting schedules. The contract uses this interface to ensure that token transfers don't exceed the available vesting balance.

The contract overrides the _beforeTokenTransfer and _afterTokenTransfer functions to implement additional logic for checking vesting and transferring vested tokens. The _spendAllowance function is also overridden to allow for default spenders that don't require an explicit approval.

The contract has several setter and getter functions for modifying the vesting contract, default spenders, and pause state. It also has functions for minting, burning, and putting tokens on hold for a specific address. The contract uses the OpenZeppelin initializer function to initialize the contract during deployment.

Overall, this contract is a solid implementation of an ERC20 token with additional functionality for vesting and access control.
# Vesting

This is a Solidity smart contract for vesting tokens. It includes several structs to define the vesting plan, volume by wallet, and plans by token and user. There are also functions to create a vesting plan, get the locked amount of tokens, and update the used volume after a transfer.

The initialize() function is the initializer that sets the owner of the contract using the OpenZeppelin __Ownable_init() function.

The createVesting() function creates a new vesting plan for a user and token. It transfers the amount of tokens from the sender (msg.sender) to the user, and adds the plan to the vesting mapping. It also emits a NewVestingPlan event.

The getAmountLock() function calculates the locked amount of tokens for a user and token. It loops through all the plans for the user and token, and calls the _getAmountLock() function for each plan to calculate the locked amount. It also checks the rollover value for each plan, and reduces the volume available for future plans.

The getAmountLockBySpender() function calculates the locked amount of tokens for a user and token, excluding the spender. It simply calls the getAmountLock() function and returns the result if the spender is not excluded for the token, or 0 if it is excluded.

The transfer() function is called by the transfer() function of the token contract. It updates the used volume for the sender, and releases the locked tokens for the receiver. If the receiver is a special spender for the token, it reduces the lock amount to the maximum possible. The function loops through all the plans for the sender and token, and calls the _getAmountLock() function for each plan to calculate the locked and free amounts. It also updates the plan released amount and the active plan index.
