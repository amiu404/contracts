//SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.17;

import "../upgradeable/Upgradeable.sol";
import "../token/IERC20.sol";
import "../vesting/IVesting.sol";
import "./IReferral.sol";

import {SignatureChecker} from "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";

contract Lockdrop is Upgradeable {
    using SignatureChecker for address;

    struct Plan {
        uint96 minAmount;
        uint96 maxAmount;
        uint16 lockDuration;
        uint16 vestingDuration;
        uint16 dropRate;
        uint16 boostedRate;
    }

    struct Campaign {
        uint32 startTime;
        uint32 endTime;
        uint32 dropVestingDuration;
        uint32 status;
        uint96 totalDropAmount;
        mapping(address => bool) stableTokens;
        address returnToken; // token equal to stablecoin - used to return to user
        mapping(uint256 => Plan) plans;
        address dropToken;
    }

    uint32 constant STATUS_PENDING = 0;
    uint32 constant STATUS_OPEN = 1;
    uint32 constant STATUS_CLAIMABLE = 2;

    uint32 constant PERCENTAGE_BASE = 1000;

    struct CampaignData {
        uint128 totalLock;
        uint64 totalShares;
        uint64 decimals;
        mapping(address => uint256) userShares;
        mapping(address => uint256) userDropped;
    }

    mapping(uint256 => Campaign) campaigns;
    mapping(uint256 => CampaignData) campaignDatas;

    IVestingContract public vestingContract;

    address public treasuryAddress;

    IReferral public referralContract;

    event Locked(
        address user,
        uint256 campaignId,
        uint256 planId,
        uint256 amount,
        address token,
        address referrer,
        uint256 shares
    );

    event Claimed(address user, uint256 campaignId, uint256 amount);

    // Initialize
    function initialize(
        address vestingContractAddress,
        address referralContractAddress
    ) public initializer {
        __Ownable_init();
        // transferOwnership(owner);
        vestingContract = IVestingContract(vestingContractAddress);
        referralContract = IReferral(referralContractAddress);
    }

    // USER ACTIONS
    function lockdrop(
        uint256 campaignId,
        uint256 planId,
        uint256 amount, // without decimals
        address tokenAddress,
        address referrer
    ) external {
        require(
            campaigns[campaignId].status == STATUS_OPEN &&
                campaigns[campaignId].startTime <= block.timestamp &&
                campaigns[campaignId].endTime > block.timestamp &&
                campaigns[campaignId].plans[planId].dropRate > 0 &&
                campaigns[campaignId].stableTokens[tokenAddress] == true,
            "Lockdrop: Invalid Campaign Or Input Data"
        );
        require(
            (campaigns[campaignId].plans[planId].minAmount == 0 ||
                campaigns[campaignId].plans[planId].minAmount <= amount) &&
                (campaigns[campaignId].plans[planId].maxAmount == 0 ||
                    campaigns[campaignId].plans[planId].maxAmount >= amount),
            "Lockdrop: Invalid Amount"
        );

        // check referrer
        address _referrer = _checkReferrer(campaignId, referrer);

        // lock stablecoin and return token with a vesting plan
        uint88 _amount = _lock(campaignId, planId, amount, tokenAddress);

        // update data
        campaignDatas[campaignId].totalLock += _amount;

        // calculate drop in shares
        uint96 _rate = campaigns[campaignId].plans[planId].dropRate;

        // and boostedRate
        _rate +=
            ((campaigns[campaignId].endTime - campaigns[campaignId].startTime) /
                1 days) *
            campaigns[campaignId].plans[planId].boostedRate;
        // boost by referrer
        if (_referrer != address(0)) {
            _rate =
                (_rate *
                    (PERCENTAGE_BASE +
                        referralContract.boostedRate(campaignId, _referrer))) /
                PERCENTAGE_BASE;
        }
        uint64 _shares = uint64(
            (_amount * _rate) / campaignDatas[campaignId].decimals
        );
        campaignDatas[campaignId].totalShares += _shares;
        campaignDatas[campaignId].userShares[msg.sender] += _shares;
        // add shares to referrer
        if (_referrer != address(0)) {
            uint64 _bonusShares = (_shares *
                referralContract.bonusRate(
                    campaignId,
                    campaignDatas[campaignId].userShares[_referrer]
                )) / PERCENTAGE_BASE;
            campaignDatas[campaignId].totalShares += _bonusShares;
            campaignDatas[campaignId].userShares[_referrer] += _bonusShares;
        }

        emit Locked(
            msg.sender,
            campaignId,
            planId,
            amount,
            tokenAddress,
            _referrer,
            _shares
        );
    }

    function claimDrop(uint256 campaignId) external {
        require(
            campaigns[campaignId].status == STATUS_CLAIMABLE &&
                campaigns[campaignId].endTime < block.timestamp &&
                campaigns[campaignId].dropToken != address(0),
            "Lockdrop: Not Ready for Drop"
        );

        uint256 droppable = totalDropOf(msg.sender, campaignId);
        droppable -= totalDroppedOf(msg.sender, campaignId);
        require(droppable > 0, "Lockdrop: No Droppable Available");

        // transfer or vesting
        if (campaigns[campaignId].dropVestingDuration > 0) {
            // approve vestingContract use droppable token
            IERC20(campaigns[campaignId].dropToken).approve(
                address(vestingContract),
                droppable
            );
            // send to user through vesting contract
            vestingContract.createVesting(
                msg.sender,
                uint88(droppable),
                campaigns[campaignId].dropToken,
                0,
                0,
                uint16(campaigns[campaignId].dropVestingDuration),
                0
            );
        } else {
            require(
                IERC20(campaigns[campaignId].dropToken).transfer(
                    msg.sender,
                    droppable
                ),
                "Lockdrop: Cannot Drop"
            );
        }

        // mark as dropped
        campaignDatas[campaignId].userDropped[msg.sender] += droppable;

        emit Claimed(msg.sender, campaignId, droppable);
    }

    // SETTER
    function setTreasuryAddress(address newTreasuryAddress) external onlyOwner {
        treasuryAddress = newTreasuryAddress;
    }

    function setVestingContract(
        address vestingContractAddress
    ) external onlyOwner {
        vestingContract = IVestingContract(vestingContractAddress);
    }

    function setReferralContract(
        address referralContractAddress
    ) external onlyOwner {
        referralContract = IReferral(referralContractAddress);
    }

    function createCampaign(
        uint256 campaignId,
        uint32 startTime,
        uint32 endTime,
        uint32 dropVestingDuration,
        uint96 totalDropAmount,
        address[] memory stableTokens,
        address returnToken,
        address dropToken
    ) external onlyOwner {
        require(
            campaigns[campaignId].endTime == 0,
            "Lockdrop: Campaign Already Existed"
        );

        campaigns[campaignId].startTime = startTime;
        campaigns[campaignId].endTime = endTime;
        for (uint256 i; i < stableTokens.length; i++) {
            campaigns[campaignId].stableTokens[stableTokens[i]] = true;
        }
        campaigns[campaignId].returnToken = returnToken;
        campaigns[campaignId].dropToken = dropToken;
        campaigns[campaignId].totalDropAmount = totalDropAmount;
        campaigns[campaignId].dropVestingDuration = dropVestingDuration;

        campaignDatas[campaignId].decimals = uint64(
            10 ** IERC20(returnToken).decimals()
        );
    }

    function setCampaignPlan(
        uint256 campaignId,
        uint256 planId,
        uint96 minAmount,
        uint96 maxAmount,
        uint16 lockDuration,
        uint16 vestingDuration,
        uint16 dropRate,
        uint16 boostedRate
    ) external onlyOwner {
        require(
            campaigns[campaignId].endTime > block.timestamp,
            "Lockdrop: Campaign Already Ended"
        );
        require(
            campaigns[campaignId].plans[planId].dropRate == 0,
            "Lockdrop: Campaign Plan Already Existed"
        );

        campaigns[campaignId].plans[planId].minAmount = minAmount;
        campaigns[campaignId].plans[planId].maxAmount = maxAmount;
        campaigns[campaignId].plans[planId].lockDuration = lockDuration;
        campaigns[campaignId].plans[planId].vestingDuration = vestingDuration;
        campaigns[campaignId].plans[planId].dropRate = dropRate;
        campaigns[campaignId].plans[planId].boostedRate = boostedRate;
    }

    function setCampaignDropToken(
        uint256 campaignId,
        address dropToken
    ) external onlyOwner {
        require(
            campaigns[campaignId].status != STATUS_CLAIMABLE,
            "Lockdrop: Invalid Campaign Status"
        );
        campaigns[campaignId].dropToken = dropToken;
    }

    function setCampaignStatus(
        uint256 campaignId,
        uint32 status
    ) external onlyOwner {
        if (status == STATUS_CLAIMABLE) {
            // check drop token before allow switch to Claimable status
            require(
                campaigns[campaignId].dropToken != address(0),
                "Lockdrop: Drop Token Is Not SET"
            );
            require(
                IERC20(campaigns[campaignId].dropToken).balanceOf(
                    address(this)
                ) >= campaigns[campaignId].totalDropAmount,
                "Lockdrop: Not Enough Drop Token"
            );
        }
        campaigns[campaignId].status = status;
    }

    // widthdraw ERC20 token in accident transfer in
    function widthdrawToken(address tokenAddress) external onlyOwner {
        IERC20 _token = IERC20(tokenAddress);
        uint256 _balance = _token.balanceOf(address(this));
        require(_balance > 0, "Lockdrop: Token Not Available");
        _token.transfer(msg.sender, _balance);
    }

    // GETTER
    function getCampaignInfo(
        uint256 campaignId
    )
        external
        view
        returns (
            uint32 startTime,
            uint32 endTime,
            uint32 dropVestingDuration,
            uint32 status,
            uint96 totalDropAmount,
            address returnToken,
            address dropToken
        )
    {
        startTime = campaigns[campaignId].startTime;
        endTime = campaigns[campaignId].endTime;
        dropVestingDuration = campaigns[campaignId].dropVestingDuration;
        status = campaigns[campaignId].status;
        totalDropAmount = campaigns[campaignId].totalDropAmount;
        returnToken = campaigns[campaignId].returnToken;
        dropToken = campaigns[campaignId].dropToken;
    }

    function tokenPerShare(uint256 campaignId) public view returns (uint256) {
        return
            campaignDatas[campaignId].totalShares > 0
                ? campaigns[campaignId].totalDropAmount /
                    campaignDatas[campaignId].totalShares
                : 0;
    }

    function totalDropOf(
        address account,
        uint256 campaignId
    ) public view returns (uint256) {
        return
            campaignDatas[campaignId].userShares[account] *
            tokenPerShare(campaignId);
    }

    function totalDroppedOf(
        address account,
        uint256 campaignId
    ) public view returns (uint256) {
        return campaignDatas[campaignId].userDropped[account];
    }

    function sharesOf(
        address account,
        uint256 campaignId
    ) public view returns (uint256) {
        return campaignDatas[campaignId].userShares[account];
    }

    function totalShares(uint256 campaignId) public view returns (uint256) {
        return campaignDatas[campaignId].totalShares;
    }

    function totalLock(uint256 campaignId) public view returns (uint256) {
        return campaignDatas[campaignId].totalLock;
    }

    // PRIVATE
    function _lockToken(address tokenAddress, uint256 amount) private {
        require(treasuryAddress != address(0), "Lockdrop: Treasury Not Found");
        require(
            IERC20(tokenAddress).transferFrom(
                msg.sender,
                treasuryAddress,
                amount
            ),
            "Lockdrop: Cannot Lock Stablecoin"
        );
    }

    function _getDropRate(
        uint256 campaignId,
        uint256 planId
    ) private view returns (uint256) {}

    function _getBonusForReferrer(
        uint256 campaignId,
        uint256 planId
    ) private view returns (uint256) {}

    function _checkReferrer(
        uint256 campaignId,
        address referrer
    ) private returns (address) {
        if (
            address(referralContract) == address(0) ||
            !referralContract.isEnabled(campaignId, address(this))
        ) return address(0);

        return
            referralContract.checkReferrer(
                campaignId,
                msg.sender,
                referrer,
                campaignDatas[campaignId].userShares[referrer]
            );
    }

    function _lock(
        uint256 campaignId,
        uint planId,
        uint amount,
        address tokenAddress
    ) private returns (uint88) {
        // transfer
        _lockToken(
            tokenAddress,
            amount * (10 ** IERC20(tokenAddress).decimals())
        );

        // amount in zk
        uint88 _amount = uint88((amount * campaignDatas[campaignId].decimals));

        // mint the returnToken
        IERC20(campaigns[campaignId].returnToken).mint(address(this), _amount);
        // approve vestingContract get returnToken
        IERC20(campaigns[campaignId].returnToken).approve(
            address(vestingContract),
            _amount
        );

        vestingContract.createVesting(
            msg.sender,
            _amount,
            campaigns[campaignId].returnToken,
            campaigns[campaignId].endTime,
            campaigns[campaignId].plans[planId].lockDuration,
            campaigns[campaignId].plans[planId].vestingDuration,
            0
        );

        return _amount;
    }
}
