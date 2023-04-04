# Goal3.xyz Lockdrop
This is a smart contract written in Solidity. The contract is a lockdrop contract that allows users to lock a stablecoin for a specific duration in exchange for a certain amount of shares in a campaign. The shares can later be exchanged for a token that is being dropped by the campaign. The contract also has a referral program where referrers can earn additional shares for their referrals.

The contract has a struct called "Plan" which contains the minimum and maximum amount of stablecoin that can be locked, the lock duration, the vesting duration, the drop rate, and the boosted rate. There is also a struct called "Campaign" which contains the start and end time of the campaign, the duration of the drop vesting, the campaign status, the total drop amount, and other mappings related to the campaign.

The contract also has a struct called "CampaignData" which contains the total amount of stablecoin locked, the total number of shares, and other mappings related to the users who have participated in the campaign.

The contract has functions for initializing the contract, locking stablecoin and earning shares, claiming the dropped token, and checking the amount of stablecoin locked and the amount of the dropped token claimed by a user. The contract also has a function for checking the referrer of a user and calculating the bonus shares for the referrer.

The contract uses other contracts such as the "Upgradeable" contract, the "IERC20" interface, the "IVesting" interface, and the "IReferral" interface. The contract also uses the "SignatureChecker" library from the OpenZeppelin library for checking the signature of an address.
