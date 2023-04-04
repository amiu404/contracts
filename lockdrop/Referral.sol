//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

import "../upgradeable/Upgradeable.sol";

interface ICaller {
    function referralContract() external view returns (address);
}

contract Referral is Upgradeable {
    struct ReferralCampaign {
        address fromContract;
        uint256[] bonusAmountByLevels;
        uint16[] bonusRateByLevels;
        uint16 defaultBoostedRate;
        bool required;
        mapping(address => address) referees;
        mapping(address => uint16) boostedRateByReferrers;
        mapping(address => bool) whitelisted;
    }

    mapping(uint256 => ReferralCampaign) referrals;

    // Initialize
    function initialize() public initializer {
        __Ownable_init();
    }

    // Add Referral by contract
    function checkReferrer(
        uint256 campaignId,
        address referee,
        address referrer,
        uint256 referrerVolume
    ) external returns (address) {
        require(
            ICaller(msg.sender).referralContract() == address(this),
            "Invalid Caller"
        );

        // No referrer for whitelisted
        if (referrals[campaignId].whitelisted[referee]) return address(0);

        // current referrer - ignore new referrer
        address _currentReferrer = referrals[campaignId].referees[referee];
        if (_currentReferrer != address(0)) return _currentReferrer;

        // require referrer locked
        require(
            referrer != address(0) && referrerVolume > 0,
            "Lockdrop: Not Valid Referrer"
        );

        // update referrer
        referrals[campaignId].referees[referee] = referrer;

        return referrer;
    }

    // SETTER
    function createCampaign(
        uint256 campaignId,
        address fromContract,
        uint256[] memory bonusAmountByLevels,
        uint16[] memory bonusRateByLevels, // percentage, base on 1000
        uint16 defaultBoostedRate,
        bool required
    ) external onlyOwner {
        require(
            fromContract != address(0),
            "Referral: Invalid Caller Contract"
        );
        require(
            bonusAmountByLevels.length == bonusRateByLevels.length,
            "Referral: Invalid Bonus Levels Input"
        );
        require(
            referrals[campaignId].fromContract == address(0),
            "Referral: Invalid Campaign ID"
        );
        // require
        referrals[campaignId].fromContract = fromContract;
        referrals[campaignId].bonusAmountByLevels = bonusAmountByLevels;
        referrals[campaignId].bonusRateByLevels = bonusRateByLevels;
        referrals[campaignId].defaultBoostedRate = defaultBoostedRate;
        referrals[campaignId].required = required;
    }

    function setBoostedRateByReferrers(
        uint256 campaignId,
        address[] memory referrers,
        uint16[] memory boostedRates
    ) external onlyOwner {
        require(
            referrals[campaignId].fromContract != address(0),
            "Referral: Invalid Campaign"
        );
        // require
        for (uint i; i < referrers.length; i++) {
            referrals[campaignId].boostedRateByReferrers[
                referrers[i]
            ] = boostedRates[i];
        }
    }

    function setBonusRates(
        uint256 campaignId,
        uint256[] memory bonusAmountByLevels,
        uint16[] memory bonusRateByLevels
    ) external onlyOwner {
        require(
            referrals[campaignId].fromContract != address(0),
            "Referral: Invalid Campaign"
        );
        referrals[campaignId].bonusAmountByLevels = bonusAmountByLevels;
        referrals[campaignId].bonusRateByLevels = bonusRateByLevels;
    }

    function setWhitelisted(
        uint256 campaignId,
        address[] memory accounts,
        bool allow
    ) external onlyOwner {
        require(
            referrals[campaignId].fromContract != address(0),
            "Referral: Invalid Campaign"
        );

        for (uint i; i < accounts.length; i++) {
            referrals[campaignId].whitelisted[accounts[i]] = allow;
        }
    }

    // GETTER
    function getReferrer(
        uint256 campaignId,
        address referee
    ) external view returns (address) {
        return referrals[campaignId].referees[referee];
    }

    function isEnabled(
        uint256 campaignId,
        address fromContract
    ) external view returns (bool) {
        return referrals[campaignId].fromContract == fromContract;
    }

    function isRequred(uint256 campaignId) external view returns (bool) {
        return referrals[campaignId].required;
    }

    function isWhitelisted(
        uint256 campaignId,
        address account
    ) external view returns (bool) {
        return referrals[campaignId].whitelisted[account];
    }

    function bonusRate(
        uint256 campaignId,
        uint256 currentAmount
    ) external view returns (uint16) {
        uint _level;
        while (
            _level < referrals[campaignId].bonusAmountByLevels.length &&
            currentAmount >= referrals[campaignId].bonusAmountByLevels[_level]
        ) _level++;
        return
            _level > 0
                ? referrals[campaignId].bonusRateByLevels[_level - 1]
                : 0;
    }

    function boostedRate(
        uint256 campaignId,
        address referrer
    ) external view returns (uint16 _boostedRate) {
        _boostedRate = referrals[campaignId].defaultBoostedRate;
        if (referrals[campaignId].whitelisted[referrer]) _boostedRate *= 2;
    }
}
