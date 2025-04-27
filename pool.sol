// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

// OpenZeppelin libraries for ERC20 interface, safe math, and ownership control
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MetaplayxStaking is Ownable {

    IERC20 public metaplayxToken;

    // Reward tokens (ILV, SLP, GALA, SAND, MANA, etc.)
    IERC20[] public rewardTokens;

    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public totalStaked;

    uint256 public accRewardPerShare;  // Accumulated rewards per share (scaled)
    uint256 private constant PRECISION = 1e18;

    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 rewardAmount);

    constructor(address _metaplayxToken, address[] memory _rewardTokens) {
        metaplayxToken = IERC20(_metaplayxToken);

        for (uint i = 0; i < _rewardTokens.length; i++) {
            rewardTokens.push(IERC20(_rewardTokens[i]));
        }
    }

    // Stake Metaplayx tokens
    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake zero amount");

        StakeInfo storage user = stakes[msg.sender];

        updatePool();

        if (user.amount > 0) {
            uint256 pendingReward = (user.amount * accRewardPerShare) / PRECISION - user.rewardDebt;
            if (pendingReward > 0) {
                _safeRewardTransfer(msg.sender, pendingReward);
            }
        }

        metaplayxToken.transferFrom(msg.sender, address(this), _amount);

        user.amount += _amount;
        totalStaked += _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / PRECISION;

        emit Staked(msg.sender, _amount);
    }

    // Withdraw staked Metaplayx tokens
    function withdraw(uint256 _amount) external {
        StakeInfo storage user = stakes[msg.sender];
        require(user.amount >= _amount, "Withdraw amount exceeds balance");

        updatePool();

        uint256 pendingReward = (user.amount * accRewardPerShare) / PRECISION - user.rewardDebt;
        if (pendingReward > 0) {
            _safeRewardTransfer(msg.sender, pendingReward);
        }

        user.amount -= _amount;
        totalStaked -= _amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / PRECISION;

        metaplayxToken.transfer(msg.sender, _amount);

        emit Withdrawn(msg.sender, _amount);
    }

    // Claim pending rewards
    function claimRewards() external {
        StakeInfo storage user = stakes[msg.sender];

        updatePool();

        uint256 pendingReward = (user.amount * accRewardPerShare) / PRECISION - user.rewardDebt;
        require(pendingReward > 0, "No rewards to claim");

        _safeRewardTransfer(msg.sender, pendingReward);

        user.rewardDebt = (user.amount * accRewardPerShare) / PRECISION;

        emit RewardClaimed(msg.sender, pendingReward);
    }

    // Update reward pool
    function updatePool() public {
        if (totalStaked == 0) {
            return;
        }

        uint256 totalNewRewards = 0;
        for (uint i = 0; i < rewardTokens.length; i++) {
            uint256 balance = rewardTokens[i].balanceOf(address(this));
            totalNewRewards += balance;
        }

        if (totalNewRewards > 0) {
            accRewardPerShare += (totalNewRewards * PRECISION) / totalStaked;
        }
    }

    // Admin function to manually deposit rewards
    function depositRewards(uint256 _amount, uint256 _tokenIndex) external {
        require(_tokenIndex < rewardTokens.length, "Invalid token index");
        require(_amount > 0, "Cannot deposit zero");

        rewardTokens[_tokenIndex].transferFrom(msg.sender, address(this), _amount);
    }

    // Internal safe transfer of rewards
    function _safeRewardTransfer(address _to, uint256 _amount) internal {
        for (uint i = 0; i < rewardTokens.length; i++) {
            uint256 balance = rewardTokens[i].balanceOf(address(this));
            if (balance >= _amount) {
                rewardTokens[i].transfer(_to, _amount);
                return;
            }
        }
        revert("Not enough rewards available");
    }

    // Admin: Add new reward token (future expansions)
    function addRewardToken(address _newToken) external onlyOwner {
        rewardTokens.push(IERC20(_newToken));
    }
}
