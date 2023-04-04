//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

interface IVestingContract {
    function createVesting(
        address user,
        uint88 amount,
        address token,
        uint32 startTime,
        uint16 lockDuration,
        uint16 vestingDuration,
        uint16 rollover
    ) external;

    function getAmountLock(
        address user,
        address token
    ) external view returns (uint256);

    function getAmountLockBySpender(
        address user,
        address token,
        address spender
    ) external view returns (uint256);

    function transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) external;
}
