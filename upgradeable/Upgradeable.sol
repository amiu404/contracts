//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts/proxy/utils/UUPSUpgradeable.sol";

contract Upgradeable is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    constructor() {
        _disableInitializers();
    }

    // authorizeUpgrade
    function _authorizeUpgrade(
        address newImplementation
    ) internal override onlyOwner {}
}
