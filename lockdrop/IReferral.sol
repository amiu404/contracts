//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

interface IReferral {
    function getReferrer(
        uint256 campaignId,
        address referee
    ) external view returns (address);

    function checkReferrer(
        uint256 campaignId,
        address referee,
        address referrer,
        uint256 referrerVolume
    ) external returns (address);

    function isRequred(uint256 campaignId) external view returns (bool);

    function isEnabled(
        uint256 campaignId,
        address fromContract
    ) external view returns (bool);

    function bonusRate(
        uint256 campaignId,
        uint256 currentShares
    ) external view returns (uint16);

    function boostedRate(
        uint256 campaignId,
        address referrer
    ) external view returns (uint16);

    function isWhitelisted(
        uint256 campaignId,
        address account
    ) external view returns (bool);
}
