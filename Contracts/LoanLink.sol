// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Project {
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 yesVotes;
        uint256 noVotes;
        uint256 endTime;
        bool active;
        address creator;
    }
    
    struct Voter {
        bool hasVoted;
        uint256 proposalId;
        bool vote; // true for yes, false for no
    }
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => mapping(uint256 => Voter)) public voters;
    mapping(address => bool) public registeredVoters;
    
    uint256 public proposalCount;
    address public owner;
    
    event ProposalCreated(uint256 indexed proposalId, string title, address indexed creator);
    event VoteCast(uint256 indexed proposalId, address indexed voter, bool vote);
    event VoterRegistered(address indexed voter);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can perform this action");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(registeredVoters[msg.sender], "You must be a registered voter");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        registeredVoters[msg.sender] = true; // Owner is automatically registered
    }
    
    // Core Function 1: Create a new proposal
    function createProposal(
        string memory _title,
        string memory _description,
        uint256 _durationInMinutes
    ) public onlyRegisteredVoter returns (uint256) {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(_durationInMinutes > 0, "Duration must be greater than 0");
        
        proposalCount++;
        uint256 endTime = block.timestamp + (_durationInMinutes * 60);
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            yesVotes: 0,
            noVotes: 0,
            endTime: endTime,
            active: true,
            creator: msg.sender
        });
        
        emit ProposalCreated(proposalCount, _title, msg.sender);
        return proposalCount;
    }
    
    // Core Function 2: Vote on a proposal
    function vote(uint256 _proposalId, bool _vote) public onlyRegisteredVoter {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        require(proposals[_proposalId].active, "Proposal is not active");
        require(block.timestamp < proposals[_proposalId].endTime, "Voting period has ended");
        require(!voters[msg.sender][_proposalId].hasVoted, "You have already voted on this proposal");
        
        voters[msg.sender][_proposalId] = Voter({
            hasVoted: true,
            proposalId: _proposalId,
            vote: _vote
        });
        
        if (_vote) {
            proposals[_proposalId].yesVotes++;
        } else {
            proposals[_proposalId].noVotes++;
        }
        
        emit VoteCast(_proposalId, msg.sender, _vote);
    }
    
    // Core Function 3: Get proposal results and details
    function getProposalResults(uint256 _proposalId) public view returns (
        string memory title,
        string memory description,
        uint256 yesVotes,
        uint256 noVotes,
        uint256 endTime,
        bool active,
        address creator,
        bool hasEnded
    ) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Invalid proposal ID");
        
        Proposal memory proposal = proposals[_proposalId];
        bool hasEnded = block.timestamp >= proposal.endTime;
        
        return (
            proposal.title,
            proposal.description,
            proposal.yesVotes,
            proposal.noVotes,
            proposal.endTime,
            proposal.active && !hasEnded,
            proposal.creator,
            hasEnded
        );
    }
    
    // Helper function: Register a new voter (only owner can do this)
    function registerVoter(address _voter) public onlyOwner {
        require(!registeredVoters[_voter], "Voter is already registered");
        registeredVoters[_voter] = true;
        emit VoterRegistered(_voter);
    }
    
    // Helper function: Get all active proposals
    function getActiveProposals() public view returns (uint256[] memory) {
        uint256[] memory activeIds = new uint256[](proposalCount);
        uint256 count = 0;
        
        for (uint256 i = 1; i <= proposalCount; i++) {
            if (proposals[i].active && block.timestamp < proposals[i].endTime) {
                activeIds[count] = i;
                count++;
            }
        }
        
        // Create a new array with the correct size
        uint256[] memory result = new uint256[](count);
        for (uint256 j = 0; j < count; j++) {
            result[j] = activeIds[j];
        }
        
        return result;
    }
    
    // Helper function: Check if user has voted on a specific proposal
    function hasUserVoted(address _voter, uint256 _proposalId) public view returns (bool) {
        return voters[_voter][_proposalId].hasVoted;
    }
    
    // Helper function: Get user's vote on a specific proposal
    function getUserVote(address _voter, uint256 _proposalId) public view returns (bool) {
        require(voters[_voter][_proposalId].hasVoted, "User has not voted on this proposal");
        return voters[_voter][_proposalId].vote;
    }
}
