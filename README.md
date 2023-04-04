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

#
