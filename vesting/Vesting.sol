//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

import "../upgradeable/Upgradeable.sol";
import "../token/IERC20.sol";

contract Vesting is Upgradeable {
    struct Plan {
        uint32 startTime;
        uint16 lockDuration; // how many days
        uint16 vestingDuration; // days
        uint16 rollover; // how many times of volume
        uint88 amount;
        uint88 released;
    }

    struct Plans {
        uint256 idx;
        Plan[] plans;
    }

    struct Volume {
        address owner;
        uint256 total;
        uint256 used;
    }

    // volume by wallet
    mapping(address => Volume) volumes;

    // spender to count rollover volume
    mapping(address => mapping(address => bool)) spenders; // spender => token => bool

    mapping(address => mapping(address => Plans)) vesting;

    event NewVestingPlan(address user, address token, Plan plan);

    // Allow Locking token can spend on special SMC
    mapping(address => mapping(address => bool)) specialSpenders; // spender => token => bool

    // Initialize
    function initialize() public initializer {
        __Ownable_init();
    }

    function createVesting(
        address user,
        uint88 amount,
        address token,
        uint32 startTime,
        uint16 lockDuration,
        uint16 vestingDuration,
        uint16 rollover
    ) external {
        IERC20 _token = IERC20(token);
        // make sure token use this Vesting
        require(
            _token.vestingContract() == address(this),
            "Vesting: Invalid Token"
        );

        // transfer from msg.sender to user
        require(
            _token.transferFrom(msg.sender, user, amount),
            "Vesting: Transfer Token Fail"
        );

        // now add new plan
        Plan memory plan;
        plan.startTime = startTime > 0 ? startTime : uint32(block.timestamp);
        plan.lockDuration = lockDuration;
        plan.vestingDuration = vestingDuration;
        plan.rollover = rollover;
        plan.amount = amount;
        vesting[user][token].plans.push(plan);

        emit NewVestingPlan(user, token, plan);
    }

    function getAmountLock(
        address user,
        address token
    ) public view returns (uint256) {
        uint256 lockAmount;
        Plans memory _plans = vesting[user][token];
        if (_plans.idx >= _plans.plans.length) return 0; // no lock plan available

        uint256 _volume = volumes[user].total - volumes[user].used;
        //
        for (uint256 i = _plans.idx; i < _plans.plans.length; i++) {
            Plan memory _plan = _plans.plans[i];
            (uint256 _lockAmount, uint256 _freeAmount) = _getAmountLock(
                _plan,
                _volume
            );
            lockAmount += _lockAmount;
            _volume = (_volume > _freeAmount * _plan.rollover)
                ? _volume - _freeAmount * _plan.rollover
                : 0;
        }
        return lockAmount;
    }

    function getAmountLockBySpender(
        address user,
        address token,
        address spender
    ) external view returns (uint256) {
        // check if spender is excluded for this token
        if (spender != address(0) && specialSpenders[token][spender]) return 0;
        return getAmountLock(user, token);
    }

    // A transfer => update spender
    function transfer(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        // only call inside token
        require(token == msg.sender, "Vesting: Invalid Caller");

        uint256 _volume = volumes[from].total - volumes[from].used;

        Plans storage _plans = vesting[from][token];
        uint256 _idx = _plans.idx;
        uint256 _amount = 0;
        uint256 _usedVolume;

        for (uint256 i = _plans.idx; i < _plans.plans.length; i++) {
            Plan storage _plan = _plans.plans[i];

            if (specialSpenders[to][token]) {
                // check current plan available amount and reduce lock amount
                uint256 _leftAmount = _plan.amount - _plan.released;
                if (_amount + _leftAmount > amount) {
                    // miximum reduce lock amount
                    _plan.amount -= uint88(amount - _amount);
                } else {
                    // remove all current lock amount
                    _plan.amount = _plan.released;
                    _idx++;
                }
                _amount += _leftAmount;
            } else {
                (uint256 _lockAmount, uint256 _freeAmount) = _getAmountLock(
                    _plan,
                    _volume - _usedVolume
                );
                _amount += _freeAmount;
                uint256 _usedAmount = _amount > amount
                    ? _freeAmount + amount - _amount
                    : _freeAmount;
                _plan.released += uint88(_usedAmount);
                _usedVolume += _usedAmount * _plan.rollover;
                if (_lockAmount == 0 && _idx == i) {
                    _idx++;
                }
            }
            if (_amount >= amount) {
                // done
                break;
            }
        }
        // update active index
        if (_plans.idx != _idx) _plans.idx = _idx;
        // update used volume
        if (_usedVolume > 0) volumes[from].used += _usedVolume;
        // update volume if spend on spender
        if (spenders[to][token]) {
            volumes[from].total += amount;
        }
    }

    // SETTER
    function setSpender(
        address spender,
        address token,
        bool isSet
    ) external onlyOwner {
        spenders[spender][token] = isSet;
    }

    function setSpecialSpender(
        address spender,
        address token,
        bool isSet
    ) external onlyOwner {
        specialSpenders[spender][token] = isSet;
    }

    // PRIVATE
    function _getAmountLock(
        // address user,
        // address token,
        Plan memory plan,
        uint256 availableVolume
    ) private view returns (uint256 lockAmount, uint256 freeAmount) {
        uint256 _lockByTime;
        // lock by time
        uint256 _days = block.timestamp > plan.startTime
            ? (block.timestamp - plan.startTime) / (1 days)
            : 0;
        if (_days < plan.lockDuration) {
            _lockByTime = plan.amount;
        } else if (_days < plan.vestingDuration + plan.lockDuration) {
            _lockByTime =
                (plan.amount *
                    (plan.lockDuration + plan.vestingDuration - _days - 1)) /
                plan.vestingDuration;
        }

        // lock by volume
        uint256 _lockByVolume;
        if (plan.rollover > 0) {
            uint256 _freeByVolume = availableVolume / plan.rollover;
            if (_freeByVolume < plan.amount - plan.released) {
                _lockByVolume = plan.amount - plan.released - _freeByVolume;
            }
        }
        lockAmount += _lockByTime > _lockByVolume ? _lockByTime : _lockByVolume;
        freeAmount = plan.amount - plan.released - lockAmount;
    }
}
