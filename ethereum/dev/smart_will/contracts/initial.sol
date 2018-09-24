pragma solidity ^0.4.23;

// ----------------------------------------------------------------------------
// Members DApp Project
//
// https://github.com/apguerrera/members
// https://github.com/bokkypoobah/DecentralisedFutureFundDAO
//
// Enjoy.
//
// (c) Adrian Guerrera / www.deepyr.com
// (c) BokkyPooBah / Bok Consulting Pty Ltd and
// the Babysitters Club DApp Project and 2018. The MIT Licence.
// ----------------------------------------------------------------------------



// ----------------------------------------------------------------------------
// Contract function to receive approval and execute function in one call
//
// Borrowed from MiniMeToken
// ----------------------------------------------------------------------------
contract ApproveAndCallFallBack {
    function receiveApproval(address from, uint256 tokens, address token, bytes data) public;
}


// ----------------------------------------------------------------------------
// Safe maths
// ----------------------------------------------------------------------------
library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
    }
    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
    }
    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
    }
    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
    }
}


// ----------------------------------------------------------------------------
// Owned contract
// ----------------------------------------------------------------------------
contract Owned {
    address public owner;
    address public newOwner;

    event OwnershipTransferred(address indexed _from, address indexed _to);

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    constructor() public {
        owner = msg.sender;
    }
    function transferOwnership(address _newOwner) public onlyOwner {
        newOwner = _newOwner;
    }
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
        newOwner = address(0);
    }
    function transferOwnershipImmediately(address _newOwner) public onlyOwner {
        emit OwnershipTransferred(owner, _newOwner);
        owner = _newOwner;
    }
}


// ----------------------------------------------------------------------------
// Membership Data Structure
// ----------------------------------------------------------------------------
library Member {
    struct Member {
        bool exists;
        uint index;
        string name;
    }
    struct Data {
        bool initialised;
        mapping(address => Member) entries;
        address[] index;
    }

    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    function init(Data storage self) public {
        require(!self.initialised);
        self.initialised = true;
    }
    function isMember(Data storage self, address _address) public view returns (bool) {
        return self.entries[_address].exists;
    }
    function add(Data storage self, address _address, string _name) public {
        require(!self.entries[_address].exists);
        self.index.push(_address);
        self.entries[_address] = Member(true, self.index.length - 1, _name);
        emit MemberAdded(_address, _name, self.index.length);
    }
    function remove(Data storage self, address _address) public {
        require(self.entries[_address].exists);
        uint removeIndex = self.entries[_address].index;
        emit MemberRemoved(_address, self.entries[_address].name, self.index.length - 1);
        uint lastIndex = self.index.length - 1;
        address lastIndexAddress = self.index[lastIndex];
        self.index[removeIndex] = lastIndexAddress;
        self.entries[lastIndexAddress].index = removeIndex;
        delete self.entries[_address];
        if (self.index.length > 0) {
            self.index.length--;
        }
    }
    function setName(Data storage self, address memberAddress, string _name) public {
        Member storage member = self.entries[memberAddress];
        require(member.exists);
        emit MemberNameUpdated(memberAddress, member.name, _name);
        member.name = _name;
    }
    function length(Data storage self) public view returns (uint) {
        return self.index.length;
    }
}


// ----------------------------------------------------------------------------
// Member
// ----------------------------------------------------------------------------
contract Will {
    using SafeMath for uint;
    using Members for Members.Data;

    enum ProposalType {
        EtherPayment,                      //  0 Ether payment
        AddRule,                           //  1 Add governance rule
        DeleteRule,                        //  2 Delete governance rule
        AddMember,                         //  3 Add member
        RemoveMember                       // 4 Remove member
    }

    struct Proposal {
        ProposalType proposalType;
        address proposer;
        string description;
        address address1;
        address address2;
        address recipient;
        address tokenContract;
        uint amount;
        mapping(address => bool) voted;
        uint memberVotedNo;
        uint memberVotedYes;
        address executor;
        bool open;
        uint initiated;
        uint closed;
    }

    string public name;

    Members.Data members;
    bool public initialised;
    Proposal[] proposals;

    uint public quorum = 80;
    uint public quorumDecayPerWeek = 10;
    uint public requiredMajority = 70;

    // Must be copied here to be added to the ABI
    event MemberAdded(address indexed memberAddress, string name, uint totalAfter);
    event MemberRemoved(address indexed memberAddress, string name, uint totalAfter);
    event MemberNameUpdated(address indexed memberAddress, string oldName, string newName);

    event EtherDeposited(address indexed sender, uint amount);
    event NewProposal(uint indexed proposalId, ProposalType indexed proposalType, address indexed proposer, address recipient, address tokenContract, uint amount);
    event Voted(uint indexed proposalId, address indexed voter, bool vote, uint memberVotedYes, uint memberVotedNo);
    event EtherPaid(uint indexed proposalId, address indexed sender, address indexed recipient, uint amount);

    constructor(string _name) public {
        members.init();
        name = _name;
    }
    function init(address _memberAddr, string _memberName) public {
        require(!initialised);
        initialised = true;
        members.add(_memberAddr, _memberName);
    }
    function setMemberName(string memberName) public {
        members.setName(msg.sender, memberName);
    }
    function proposeEtherPayment(string description, address _recipient, uint _amount) public {
        require(address(this).balance >= _amount);
        require(members.isMember(msg.sender));
        Proposal memory proposal = Proposal({
            proposalType: ProposalType.EtherPayment,
            proposer: msg.sender,
            description: description,
            address1: address(0),
            address2: address(0),
            recipient: _recipient,
            tokenContract: address(0),
            amount: _amount,
            memberVotedNo: 0,
            memberVotedYes: 0,
            executor: address(0),
            open: true,
            initiated: now,
            closed: 0
        });
        proposals.push(proposal);
        emit NewProposal(proposals.length - 1, proposal.proposalType, msg.sender, _recipient, address(0), _amount);
    }
    function voteNo(uint proposalId) public {
        vote(proposalId, false);
    }
    function voteYes(uint proposalId) public {
        vote(proposalId, true);
    }
    function vote(uint proposalId, bool yesNo) public {
        require(members.isMember(msg.sender));
        Proposal storage proposal = proposals[proposalId];
        require(proposal.open);
        if (!proposal.voted[msg.sender]) {
            if (yesNo) {
                proposal.memberVotedYes++;
            } else {
                proposal.memberVotedNo++;
            }
            emit Voted(proposalId, msg.sender, yesNo, proposal.memberVotedYes, proposal.memberVotedNo);
            proposal.voted[msg.sender];
        }
        if (proposal.memberVotedYes > 0 && proposal.open) {
            if (proposal.proposalType == ProposalType.EtherPayment) {
                proposal.recipient.transfer(proposal.amount);
                emit EtherPaid(proposalId, msg.sender, proposal.recipient, proposal.amount);
                proposal.executor = msg.sender;
                proposal.open = false;
            }
        }
    }

    function addMember(address _address, string _name) internal {
        members.add(_address, _name);
        token.mint(_address, tokensForNewMembers);
    }
    function removeMember(address _address) internal {
        members.remove(_address);
    }

    function numberOfMembers() public view returns (uint) {
        return members.length();
    }
    function getMembers() public view returns (address[]) {
        return members.index;
    }
    function getMemberData(address _address) public view returns (bool _exists, uint _index, string _name) {
        Members.Member memory member = members.entries[_address];
        return (member.exists, member.index, member.name);
    }
    function getMemberByIndex(uint _index) public view returns (address _member) {
        return members.index[_index];
    }

    function getQuorum(uint proposalTime, uint currentTime) public view returns (uint) {
        if (quorum > currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks)) {
            return quorum.sub(currentTime.sub(proposalTime).mul(quorumDecayPerWeek).div(1 weeks));
        } else {
            return 0;
        }
    }
    function numberOfProposals() public view returns (uint) {
        return proposals.length;
    }
    function getProposalData1(uint proposalId) public view returns (uint _proposalType, address _proposer, string _description) {
        Proposal memory proposal = proposals[proposalId];
        _proposalType = uint(proposal.proposalType);
        _proposer = proposal.proposer;
        _description = proposal.description;
    }
    function getProposalData2(uint proposalId) public view returns (address _address1, address _address2, address _recipient, address _tokenContract, uint _amount) {
        Proposal memory proposal = proposals[proposalId];
        _address1 = proposal.address1;
        _address2 = proposal.address2;
        _recipient = proposal.recipient;
        _tokenContract = proposal.tokenContract;
        _amount = proposal.amount;
    }
    function getProposalData3(uint proposalId) public view returns (uint _memberVotedNo, uint _memberVotedYes, address _executor, bool _open) {
        Proposal memory proposal = proposals[proposalId];
        _memberVotedNo = proposal.memberVotedNo;
        _memberVotedYes = proposal.memberVotedYes;
        _executor = proposal.executor;
        _open = proposal.open;
    }

    function () public payable {
        emit EtherDeposited(msg.sender, msg.value);
    }
}


// ----------------------------------------------------------------------------
// Member Factory
// ----------------------------------------------------------------------------
contract MemberFactory is Owned {

    mapping(address => bool) _verify;
    Member[] public deployedMembers;

    event MemberListing(address indexed member, string memberName,
        address indexed memberName);

    function verify(address addr) public view returns (bool valid) {
        valid = _verify[addr];
    }
    function deployMemberContract(
        string memberName,
        string memberName
    ) public returns (Member member) {
        member = new Member(memberName);
        member.init(msg.sender, memberName);
        _verify[address(member)] = true;
        deployedMembers.push(member);
        emit MemberListing(address(member), memberName, msg.sender);
    }
    function numberOfDeployedMembers() public view returns (uint) {
        return deployedMembers.length;
    }
    function numberOfDeployedTokens() public view returns (uint) {
        return deployedTokens.length;
    }
    function () public payable {
        revert();
    }
}
