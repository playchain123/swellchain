// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transfer(address recipient, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function balanceOf(address account) external view returns (uint256);
}

contract MetaPlayXRestakeDAO {
    IERC20 public immutable metaPlayX;
    address public admin;
    
    uint256 public totalStaked;
    
    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
    }

    mapping(address => StakeInfo) public stakes;
    uint256 public accRewardPerShare; // Accumulated rewards per share
    uint256 public lastRewardTime;
    uint256 public rewardRatePerSecond; // How much reward is distributed per second

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);
    event RewardClaimed(address indexed user, uint256 amount);
    event Restaked(address indexed user, uint256 amount);
    event RewardRateUpdated(uint256 newRate);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    constructor(address _metaPlayXToken) {
        metaPlayX = IERC20(_metaPlayXToken);
        admin = msg.sender;
        lastRewardTime = block.timestamp;
        rewardRatePerSecond = 1e18; // Example: 1 MetaPlayX per second
    }

    function updatePool() public {
        if (block.timestamp <= lastRewardTime || totalStaked == 0) {
            return;
        }
        uint256 secondsPassed = block.timestamp - lastRewardTime;
        uint256 rewards = secondsPassed * rewardRatePerSecond;
        accRewardPerShare += (rewards * 1e12) / totalStaked;
        lastRewardTime = block.timestamp;
    }

    function stake(uint256 amount) external {
        require(amount > 0, "Cannot stake 0");
        updatePool();
        
        StakeInfo storage user = stakes[msg.sender];
        
        if (user.amount > 0) {
            uint256 pending = (user.amount * accRewardPerShare / 1e12) - user.rewardDebt;
            if (pending > 0) {
                metaPlayX.transfer(msg.sender, pending);
                emit RewardClaimed(msg.sender, pending);
            }
        }
        
        metaPlayX.transferFrom(msg.sender, address(this), amount);
        user.amount += amount;
        totalStaked += amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;

        emit Staked(msg.sender, amount);
    }

    function unstake(uint256 amount) external {
        StakeInfo storage user = stakes[msg.sender];
        require(user.amount >= amount, "Not enough staked");
        updatePool();
        
        uint256 pending = (user.amount * accRewardPerShare / 1e12) - user.rewardDebt;
        if (pending > 0) {
            metaPlayX.transfer(msg.sender, pending);
            emit RewardClaimed(msg.sender, pending);
        }
        
        user.amount -= amount;
        totalStaked -= amount;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;

        metaPlayX.transfer(msg.sender, amount);

        emit Unstaked(msg.sender, amount);
    }

    function claimReward() external {
        updatePool();
        
        StakeInfo storage user = stakes[msg.sender];
        uint256 pending = (user.amount * accRewardPerShare / 1e12) - user.rewardDebt;
        require(pending > 0, "No rewards");
        
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;
        metaPlayX.transfer(msg.sender, pending);
        
        emit RewardClaimed(msg.sender, pending);
    }

    function restakeReward() external {
        updatePool();
        
        StakeInfo storage user = stakes[msg.sender];
        uint256 pending = (user.amount * accRewardPerShare / 1e12) - user.rewardDebt;
        require(pending > 0, "No rewards to restake");
        
        user.amount += pending;
        totalStaked += pending;
        user.rewardDebt = (user.amount * accRewardPerShare) / 1e12;

        emit Restaked(msg.sender, pending);
    }

    function setRewardRate(uint256 _rate) external onlyAdmin {
        updatePool();
        rewardRatePerSecond = _rate;
        emit RewardRateUpdated(_rate);
    }

    function pendingReward(address userAddr) external view returns (uint256) {
        StakeInfo storage user = stakes[userAddr];
        uint256 tempAccRewardPerShare = accRewardPerShare;

        if (block.timestamp > lastRewardTime && totalStaked != 0) {
            uint256 secondsPassed = block.timestamp - lastRewardTime;
            uint256 rewards = secondsPassed * rewardRatePerSecond;
            tempAccRewardPerShare += (rewards * 1e12) / totalStaked;
        }

        return (user.amount * tempAccRewardPerShare / 1e12) - user.rewardDebt;
    }
}
