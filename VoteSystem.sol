//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract VoteSystem is ReentrancyGuard, Ownable{

    IERC721 public voteToken;
    uint256 projectNumber;
    mapping (address => mapping(uint256 => bool)) voterToProjectNumberToVoteDecision;
    mapping (uint256 => projectDetails) projectNumberToProjectDetails;
    mapping (uint256 => uint256) projectNumberToYesCount;
    mapping (uint256 => uint256) projectNumberToNoCount;    
    mapping (uint256 => uint256) projectNumbertoVotersVoted;
    uint256 eligibleVoters = 5;
    bool public willProjectExecute;

    struct projectDetails {
        uint256 launchTime;
        uint256 deadline;
        uint256 yesCount;
        bool approvalStatus;
    }

    error NoVotingRights();
    error ProjectCreated();
    error VotingClose();

    constructor (address _tokenAddress)  Ownable(msg.sender) {
        voteToken = IERC721(_tokenAddress); 
    }

    function buildProject (uint256 _projectNumber, uint256 _projectDeadlines) onlyOwner external {
        if (projectNumberToProjectDetails[_projectNumber].launchTime != 0) revert ProjectCreated();
        projectDetails storage _projectDetails = projectNumberToProjectDetails[_projectNumber];
            _projectDetails.launchTime = block.timestamp;
            _projectDetails.deadline = _projectDeadlines; 
    }

    function castVote (uint256 _projectNumber, bool _yes, uint256 _tokenID) external {
        projectDetails memory _projectDetails = projectNumberToProjectDetails[_projectNumber];
        if (block.timestamp > _projectDetails.launchTime + _projectDetails.deadline * 86400 ) revert VotingClose();
        if (voteToken.ownerOf(_tokenID) != msg.sender) revert NoVotingRights();
        voterToProjectNumberToVoteDecision[msg.sender][_projectNumber] = _yes ;
        if (_yes == true) {
            projectNumberToYesCount[_projectNumber] ++;
        } 
        projectNumbertoVotersVoted[_projectNumber] ++;
        if (projectNumbertoVotersVoted[_projectNumber] == eligibleVoters){
            executeProject(_projectNumber);
        }
    }

    function checkMemberVote (address _voterAddress, uint256 _projectNumber) external view onlyOwner returns (bool) {
        return voterToProjectNumberToVoteDecision[_voterAddress][_projectNumber];
    }

    function executeProject (uint256 _projectNumber) private returns (uint256, bool) {
        if ((projectNumberToYesCount[_projectNumber]  * 2 ) > eligibleVoters) {
            return (_projectNumber , willProjectExecute = true);
        }
    }

    function projectYesCount(uint256 _projectNumber) external view onlyOwner returns(uint256) {
        return projectNumberToYesCount[_projectNumber];
    }

}
