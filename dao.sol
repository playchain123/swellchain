// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's ERC20 and SafeMath libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DaoContract is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public token; // The token that users will stake
    uint256 public totalStaked; // Total tokens staked in the DAO

    struct Proposal {
        uint256 id;
        string description; // Description of the project
        uint256 voteCount; // Number of votes for the proposal
        bool executed; // Whether the proposal has been executed
    }

    // Mapping from proposal id to Proposal
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public hasVoted;

    uint256 public proposalCount; // Count of proposals

    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, uint256 amount);
    event TokensStaked(address user, uint256 amount);
    event TokensUnstaked(address user, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Function to create a new proposal
    function createProposal(string memory _description) external onlyOwner {
        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, _description, 0, false);
        emit ProposalCreated(proposalCount, _description);
    }

    // Function to stake tokens to participate in DAO voting
    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        token.transferFrom(msg.sender, address(this), _amount);
        stakingBalance[msg.sender] = stakingBalance[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);
        emit TokensStaked(msg.sender, _amount);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, uint256 _amount) external nonReentrant {
        require(stakingBalance[msg.sender] >= _amount, "Not enough staked tokens");
        require(!hasVoted[msg.sender], "You have already voted");

        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        proposal.voteCount = proposal.voteCount.add(_amount);
        hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _amount);
    }

    // Function to unvote and unstake tokens after voting
    function unvote(uint256 _proposalId) external {
        require(hasVoted[msg.sender], "You have not voted");

        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        uint256 amount = stakingBalance[msg.sender]; // Assuming unstaking whole balance
        stakingBalance[msg.sender] = 0;
        totalStaked = totalStaked.sub(amount);
        token.transfer(msg.sender, amount);
        hasVoted[msg.sender] = false;

        emit TokensUnstaked(msg.sender, amount);
    }

    // Function to execute the proposal
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        
        // Condition to check if proposal passes (simple majority)
        require(proposal.voteCount > totalStaked.div(2), "Voting did not pass");
        
        proposal.executed = true;
        // Implement the logic to execute the proposal

        // Example: Notify execution completion
        // Add your execution logic here
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Importing OpenZeppelin's ERC20 and SafeMath libraries
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract DaoContract is ReentrancyGuard, Ownable {
    using SafeMath for uint256;

    IERC20 public token; // The token that users will stake
    uint256 public totalStaked; // Total tokens staked in the DAO

    struct Proposal {
        uint256 id;
        string description; // Description of the project
        uint256 voteCount; // Number of votes for the proposal
        bool executed; // Whether the proposal has been executed
    }

    // Mapping from proposal id to Proposal
    mapping(uint256 => Proposal) public proposals;
    mapping(address => uint256) public stakingBalance;
    mapping(address => bool) public hasVoted;

    uint256 public proposalCount; // Count of proposals

    event ProposalCreated(uint256 id, string description);
    event Voted(uint256 proposalId, address voter, uint256 amount);
    event TokensStaked(address user, uint256 amount);
    event TokensUnstaked(address user, uint256 amount);

    constructor(address _token) {
        token = IERC20(_token);
    }

    // Function to create a new proposal
    function createProposal(string memory _description) external onlyOwner {
        proposalCount++;
        proposals[proposalCount] = Proposal(proposalCount, _description, 0, false);
        emit ProposalCreated(proposalCount, _description);
    }

    // Function to stake tokens to participate in DAO voting
    function stakeTokens(uint256 _amount) external {
        require(_amount > 0, "Amount must be greater than 0");
        token.transferFrom(msg.sender, address(this), _amount);
        stakingBalance[msg.sender] = stakingBalance[msg.sender].add(_amount);
        totalStaked = totalStaked.add(_amount);
        emit TokensStaked(msg.sender, _amount);
    }

    // Function to vote on a proposal
    function vote(uint256 _proposalId, uint256 _amount) external nonReentrant {
        require(stakingBalance[msg.sender] >= _amount, "Not enough staked tokens");
        require(!hasVoted[msg.sender], "You have already voted");

        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        proposal.voteCount = proposal.voteCount.add(_amount);
        hasVoted[msg.sender] = true;

        emit Voted(_proposalId, msg.sender, _amount);
    }

    // Function to unvote and unstake tokens after voting
    function unvote(uint256 _proposalId) external {
        require(hasVoted[msg.sender], "You have not voted");

        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");

        uint256 amount = stakingBalance[msg.sender]; // Assuming unstaking whole balance
        stakingBalance[msg.sender] = 0;
        totalStaked = totalStaked.sub(amount);
        token.transfer(msg.sender, amount);
        hasVoted[msg.sender] = false;

        emit TokensUnstaked(msg.sender, amount);
    }

    // Function to execute the proposal
    function executeProposal(uint256 _proposalId) external onlyOwner {
        Proposal storage proposal = proposals[_proposalId];
        require(!proposal.executed, "Proposal already executed");
        
        // Condition to check if proposal passes (simple majority)
        require(proposal.voteCount > totalStaked.div(2), "Voting did not pass");
        
        proposal.executed = true;
        // Implement the logic to execute the proposal

        // Example: Notify execution completion
        // Add your execution logic here
    }
}


