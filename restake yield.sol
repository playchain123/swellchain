// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

contract MetaPlayXRestakeYield {
    IERC20 public immutable token;
    
    uint256 public rewardRatePerSecond; // Example: 100000000000000 wei per second (customizable)
    uint256 public totalStaked;
    
    struct StakeInfo {
        uint256 amount;
        uint256 rewardDebt;
        uint256 lastUpdate;
    }
    
    mapping(address => StakeInfo) public stakes;

    constructor(uint256 _rewardRatePerSecond) {
        token = IERC20(0xC4637Aa13B79F73F5b26B16266Fbe6b404b6aEB3);
        rewardRatePerSecond = _rewardRatePerSecond;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Stake amount must be greater than 0");

        _updateReward(msg.sender);

        token.transferFrom(msg.sender, address(this), _amount);
        stakes[msg.sender].amount += _amount;
        totalStaked += _amount;
    }

    function claimAndRestake() external {
        _updateReward(msg.sender);

        StakeInfo storage user = stakes[msg.sender];
        uint256 pending = user.rewardDebt;
        require(pending > 0, "No rewards to restake");

        user.amount += pending;  // Restake rewards automatically
        totalStaked += pending;
        user.rewardDebt = 0; // Reset pending rewards
        user.lastUpdate = block.timestamp;
    }

    function withdraw(uint256 _amount) external {
        require(_amount > 0, "Withdraw amount must be greater than 0");
        
        _updateReward(msg.sender);

        StakeInfo storage user = stakes[msg.sender];
        require(user.amount >= _amount, "Withdraw amount exceeds staked");

        user.amount -= _amount;
        totalStaked -= _amount;
        token.transfer(msg.sender, _amount);
    }

    function pendingRewards(address _user) public view returns (uint256) {
        StakeInfo storage user = stakes[_user];
        if (user.amount == 0) return user.rewardDebt;

        uint256 timeDiff = block.timestamp - user.lastUpdate;
        uint256 rewards = (user.amount * rewardRatePerSecond * timeDiff) / 1e18;
        return user.rewardDebt + rewards;
    }

    function _updateReward(address _user) internal {
        StakeInfo storage user = stakes[_user];
        if (user.amount > 0) {
            uint256 rewards = pendingRewards(_user);
            user.rewardDebt = rewards;
        }
        user.lastUpdate = block.timestamp;
    }

    function setRewardRate(uint256 _newRate) external onlyOwner {
        rewardRatePerSecond = _newRate;
    }

    address public owner = msg.sender;
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }
}
