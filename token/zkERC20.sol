//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

import "../upgradeable/Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import "../vesting/IVesting.sol";

contract zkERC20 is Upgradeable, ERC20Upgradeable, AccessControlUpgradeable {
    // new role
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BURNER_ROLE = keccak256("BURNER_ROLE");

    bool public isPaused;

    IVestingContract public vestingContract;
    mapping(address => bool) public defaultSpenders; // don't need approve on default spender

    // put some token on hold when neccesery
    mapping(address => uint256) holds;

    // constructor(string memory name, string memory symbol) ERC20(name, symbol) {
    //     _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    // }

    function initialize(
        string memory name,
        string memory symbol
    ) public initializer {
        __Ownable_init();
        __ERC20_init_unchained(name, symbol);
        __AccessControl_init_unchained();
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        require(!isPaused, "Token transfer while paused");
        if (from == address(0) || to == address(0)) return; // ignore for mint/burn
        // check lock
        require(
            freeBalanceBySpender(from, to) >= amount,
            "Vesting: transfer amount exceeds balance"
        );
    }

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal virtual override {
        if (from == address(0) || to == address(0)) return; // ignore for mint/burn
        if (address(vestingContract) != address(0)) {
            vestingContract.transfer(address(this), from, to, amount);
        }
    }

    function _spendAllowance(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual override {
        // no need to approve spend on default spenders
        if (defaultSpenders[spender] == false) {
            uint256 currentAllowance = allowance(owner, spender);
            if (currentAllowance != type(uint256).max) {
                require(
                    currentAllowance >= amount,
                    "ERC20: insufficient allowance"
                );
                unchecked {
                    _approve(owner, spender, currentAllowance - amount);
                }
            }
        }
    }

    // CONTROLLER
    function mint(address to, uint256 amount) external onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyRole(BURNER_ROLE) {
        _burn(from, amount);
    }

    function putOnHold(
        address from,
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        holds[from] = amount;
    }

    // SETTER
    function setVestingContract(
        address vestingContractAddress
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        vestingContract = IVestingContract(vestingContractAddress);
    }

    function setDefaultSpender(
        address spender,
        bool isDefault
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        defaultSpenders[spender] = isDefault;
    }

    function setPause(bool _isPaused) external onlyRole(DEFAULT_ADMIN_ROLE) {
        isPaused = _isPaused;
    }

    // GETTER
    function decimals() public view virtual override returns (uint8) {
        return 6;
    }

    function freeBalanceOf(address account) public view returns (uint256) {
        uint256 _locked = lockBalanceOf(account);
        uint256 _balance = balanceOf(account);
        return _locked < _balance ? _balance - _locked : 0;
    }

    function lockBalanceOf(address account) public view returns (uint256) {
        uint256 _lock = address(vestingContract) == address(0)
            ? 0
            : vestingContract.getAmountLock(account, address(this));
        return _lock > holds[account] ? _lock : holds[account];
    }

    function freeBalanceBySpender(
        address account,
        address spender
    ) public view returns (uint256) {
        uint256 _locked = lockBalanceBySpender(account, spender);
        uint256 _balance = balanceOf(account);
        return _locked < _balance ? _balance - _locked : 0;
    }

    function lockBalanceBySpender(
        address account,
        address spender
    ) public view returns (uint256) {
        uint256 _lock = address(vestingContract) == address(0)
            ? 0
            : vestingContract.getAmountLockBySpender(
                account,
                address(this),
                spender
            );
        return _lock > holds[account] ? _lock : holds[account];
    }
}
