// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract MetaPlayXStaking {
    IERC20 public immutable metaPlayXToken;
    address public owner;

    struct StakeInfo {
        uint256 amount;
        uint256 timestamp;
    }

    mapping(address => StakeInfo) public stakes;

    event Staked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call");
        _;
    }

    constructor(address _metaPlayXTokenAddress) {
        require(_metaPlayXTokenAddress != address(0), "Invalid token address");
        metaPlayXToken = IERC20(_metaPlayXTokenAddress);
        owner = msg.sender;
    }

    function stake(uint256 _amount) external {
        require(_amount > 0, "Cannot stake 0");
        
        // Transfer MetaPlayX tokens from user to contract
        bool success = metaPlayXToken.transferFrom(msg.sender, address(this), _amount);
        require(success, "Token transfer failed");

        stakes[msg.sender].amount += _amount;
        stakes[msg.sender].timestamp = block.timestamp;

        emit Staked(msg.sender, _amount);
    }

    function unstake(uint256 _amount) external {
        require(_amount > 0, "Cannot unstake 0");
        require(stakes[msg.sender].amount >= _amount, "Not enough staked");

        stakes[msg.sender].amount -= _amount;

        bool success = metaPlayXToken.transfer(msg.sender, _amount);
        require(success, "Token transfer failed");

        emit Unstaked(msg.sender, _amount);
    }

    function getStakedAmount(address _user) external view returns (uint256) {
        return stakes[_user].amount;
    }

    function getStakeTimestamp(address _user) external view returns (uint256) {
        return stakes[_user].timestamp;
    }
}
