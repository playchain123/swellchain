// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Adding the OpenZeppelin Contracts
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingContract is ReentrancyGuard {
    using SafeMath for uint256;

    IERC20 public stakingToken;

    struct Stake {
        uint256 amount;
        uint256 rewards;
        uint256 lastUpdate;
    }

    mapping(address => Stake) public stakes;
    uint256 public rewardRate; // Reward rate per block

    event Staked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 reward);
    event Restaked(address indexed user, uint256 restakedAmount);

    constructor(IERC20 _stakingToken, uint256 _rewardRate) {
        stakingToken = _stakingToken;
        rewardRate = _rewardRate;
    }

    // Stake tokens
    function stake(uint256 _amount) external nonReentrant {
        require(_amount > 0, "Cannot stake 0");
        
        stakes[msg.sender].rewards = _calculateRewards(msg.sender);
        stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
        stakes[msg.sender].lastUpdate = block.timestamp;

        stakingToken.transferFrom(msg.sender, address(this), _amount);
        emit Staked(msg.sender, _amount);
    }

    // Calculate rewards
    function _calculateRewards(address _user) internal view returns (uint256) {
        Stake memory userStake = stakes[_user];
        uint256 duration = block.timestamp.sub(userStake.lastUpdate);
        return userStake.amount.mul(rewardRate).mul(duration).div(1e18);
    }

    // Claim rewards
    function claimRewards() external nonReentrant {
        uint256 reward = _calculateRewards(msg.sender);
        require(reward > 0, "No rewards available");

        stakes[msg.sender].rewards = 0;
        stakes[msg.sender].lastUpdate = block.timestamp;

        stakingToken.transfer(msg.sender, reward);
        emit RewardClaimed(msg.sender, reward);
    }

    // Restake rewards
    function restakeRewards() external nonReentrant {
        uint256 reward = _calculateRewards(msg.sender);
        require(reward > 0, "No rewards to restake");

        stakes[msg.sender].rewards = 0; // Reset rewards
        stakes[msg.sender].amount = stakes[msg.sender].amount.add(reward);
        stakes[msg.sender].lastUpdate = block.timestamp;

        emit Restaked(msg.sender, reward);
    }

    // Get user's staked amount
    function getStakedAmount(address _user) external view returns (uint256) {
        return stakes[_user].amount;
    }

    // Get user's total rewards
    function getTotalRewards(address _user) external view returns (uint256) {
        return _calculateRewards(_user).add(stakes[_user].rewards);
    }
}