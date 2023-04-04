//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../vesting/IVesting.sol";

contract Goal3 is ERC20 {
    uint256 constant TOTAL_SUPPLY = 500_000_000;
    IVestingContract public vestingContract;

    constructor(
        address vestingContractAddress
    ) ERC20("Goal3.xyz Tokens", "$GOAL3") {
        vestingContract = IVestingContract(vestingContractAddress);
        _mint(msg.sender, TOTAL_SUPPLY * (10 ** decimals()));
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        // check lock
        if (
            address(vestingContract) != address(0) && amount <= balanceOf(from)
        ) {
            require(
                balanceOf(from) >=
                    amount +
                        vestingContract.getAmountLockBySpender(
                            from,
                            address(this),
                            to
                        ),
                "Vesting: transfer amount exceeds balance"
            );
        }
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (address(vestingContract) != address(0)) {
            vestingContract.transfer(address(this), from, to, amount);
        }
    }

    // GETTER
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function freeBalanceOf(address account) public view returns (uint256) {
        return balanceOf(account) - lockBalanceOf(account);
    }

    function lockBalanceOf(address account) public view returns (uint256) {
        return
            address(vestingContract) == address(0)
                ? 0
                : vestingContract.getAmountLock(account, address(this));
    }
}
