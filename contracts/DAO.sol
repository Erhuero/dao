pragma solidity ^0.8.6;
//SPDX-License-Identifier:UNLICENSED

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';

contract DAO {
    //Side to vote for each proposal
    enum Side {Yes, No}
    enum Status { Undecided, Approved, Rejected }
    struct Proposal {
        address author;
        //calculate the hash of the proposal
        bytes32 hash;
        //date
        uint createdAt;
        uint votesYes;
        uint votesNo;
        Status status;
    }
    //index the proposals by the hashes
    mapping(bytes32 => Proposal) public proposals;
    //who voted for who, identified the proposal
    mapping(address => mapping(bytes32 => bool)) public votes;
    //maps the address of the investor by shares
    mapping(address => uint) public shares;
    //keep track of what's the total amounts by share
    uint public totalShares;
    IERC20 public token;
    //shares you need to create a proposal
    uint constant CREATE_PROPOSAL_MIN_SHARE = 1000 * 10 ** 18;
    //say the voting period is seven days
    uint constant VOTING_PERIOD = 7 days;
    //uint constant VOTING_PERIOD = 7 days;

    constructor(address _token){
        //instanciate token var
        //to minapulate governance token
        token = IERC20(_token);
    }
    //how many token we want to deposit
    function deposit(uint amount) external {
        //increment the shares
        shares[msg.sender] += amount;
        //1 share = 1 governance token
        totalShares += amount;
        token.transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(uint amount) external {
        require(shares[msg.sender] >= amount, 'not enough shares');
        shares[msg.sender] -= amount;
        totalShares -= amount;
        token.transfer(msg.sender, amount);
    }

    function createProposal(bytes32 proposalHash) external {
        require(//verify if we have enough shares to create a proposal
            shares[msg.sender] >= CREATE_PROPOSAL_MIN_SHARE,
            'not enough shares to create proposal'
        );
        require(proposals[proposalHash].hash == bytes32(0), 'proposal already exist');
        proposals[proposalHash] = Proposal(
            msg.sender,
            proposalHash,
            block.timestamp,
            0,
            0,
            Status.Undecided
        );
    }
    //creating vote once the proposal is creating and wich side yes or no
    function vote(bytes32 proposalHash, Side side) external {
        Proposal storage proposal = proposals[proposalHash];
         //make sure this address not voted already
        require(votes[msg.sender][proposalHash] == false, 'already voted');

        require(proposals[proposalHash].hash != bytes32(0), 'proposal already exist');
       
        //require the proposal
        require(block.timestamp <= proposal.createdAt + VOTING_PERIOD, 'voting period over');
        votes[msg.sender][proposalHash] = true;
        if(side == Side.Yes){
            //increments YES proportional to number of shares
            proposal.votesYes += shares[msg.sender];
            //if we we have enough votes, divided by the shares
            if(proposal.votesYes * 100 / totalShares > 50){
                //update the status of the proposal
                proposal.status = Status.Approved;
            } else {
                proposal.votesNo += shares[msg.sender];
                if(proposal.votesNo * 100 / totalShares > 50){
                    proposal.status = Status.Rejected;
                }
            }
        }
    }
}