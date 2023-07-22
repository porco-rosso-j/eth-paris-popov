// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {SafeCastUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/math/SafeCastUpgradeable.sol";

import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {RATIO_BASE, _applyRatioCeiled} from "@aragon/osx/plugins/utils/Ratio.sol";

import {IMembership} from "@aragon/osx/core/plugin/membership/IMembership.sol";
import {Addresslist} from "@aragon/osx/plugins/utils/Addresslist.sol";
import {IMajorityVoting} from "../interfaces/IMajorityVoting.sol";
import {MajorityVotingBase} from "../MajorityVotingBase.sol";
import {PopovWolrdID} from "../PopovWolrdID.sol";
import {IWorldID} from "../interfaces/IWorldID.sol";
import {PopovLane} from "../hyperlane/PopovLane.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";

/// @title PopovVoting
/// @author Porco Rosso.
/// @notice The majority voting implementation using a list of member addresses.
/// @dev This contract inherits from `MajorityVotingBase` and implements the `IMajorityVoting` interface.
contract PopovVoting is
    IMembership,
    Addresslist,
    MajorityVotingBase,
    PopovWolrdID,
    PopovLane
{
    using SafeCastUpgradeable for uint256;
    using TypeCasts for bytes;

    /// @notice The [ERC-165](https://eips.ethereum.org/EIPS/eip-165) interface ID of the contract.
    bytes4 internal constant POPOV_VOTING_INTERFACE_ID =
        this.initialize.selector ^
            this.addAddresses.selector ^
            this.removeAddresses.selector; // add another selector

    /// @notice The ID of the permission required to call the `addAddresses` and `removeAddresses` functions.
    bytes32 public constant UPDATE_ADDRESSES_PERMISSION_ID =
        keccak256("UPDATE_ADDRESSES_PERMISSION");

    /// @notice Initializes the component.
    /// @dev This method is required to support [ERC-1822](https://eips.ethereum.org/EIPS/eip-1822).
    /// @param _dao The IDAO interface of the associated DAO.
    /// @param _votingSettings The voting settings.
    function initialize(
        IDAO _dao,
        VotingSettings calldata _votingSettings,
        address[] calldata _members,
        address _worldId,
        string memory _appId,
        string memory _actionId
    ) external initializer {
        __MajorityVotingBase_init(_dao, _votingSettings);

        _initializeWoldID(IWorldID(_worldId), _appId, _actionId);

        _addAddresses(_members);
        emit MembersAdded({members: _members});
    }

    /// @notice Checks if this or the parent contract supports an interface by its ID.
    /// @param _interfaceId The ID of the interface.
    /// @return Returns `true` if the interface is supported.
    function supportsInterface(
        bytes4 _interfaceId
    ) public view virtual override returns (bool) {
        return
            _interfaceId == POPOV_VOTING_INTERFACE_ID ||
            _interfaceId == type(Addresslist).interfaceId ||
            _interfaceId == type(IMembership).interfaceId ||
            super.supportsInterface(_interfaceId);
    }

    /// @notice Adds new members to the address list.
    /// @param _members The addresses of members to be added.
    /// @dev This function is used during the plugin initialization.
    function addAddresses(
        address[] calldata _members
    ) external auth(UPDATE_ADDRESSES_PERMISSION_ID) {
        _addAddresses(_members);

        emit MembersAdded({members: _members});
    }

    /// @notice Removes existing members from the address list.
    /// @param _members The addresses of the members to be removed.
    function removeAddresses(
        address[] calldata _members
    ) external auth(UPDATE_ADDRESSES_PERMISSION_ID) {
        _removeAddresses(_members);

        emit MembersRemoved({members: _members});
    }

    /// @inheritdoc MajorityVotingBase
    function totalVotingPower(
        uint256 _blockNumber
    ) public view override returns (uint256) {
        return addresslistLengthAtBlock(_blockNumber);
    }

    /// @inheritdoc MajorityVotingBase
    function createProposal(
        bytes calldata _metadata,
        IDAO.Action[] calldata _actions,
        uint256 _allowFailureMap,
        uint64 _startDate,
        uint64 _endDate,
        VoteOption _voteOption,
        bool _tryEarlyExecution
    ) external override returns (uint256 proposalId) {
        if (minProposerVotingPower() != 0 && !isListed(_msgSender())) {
            revert ProposalCreationForbidden(_msgSender());
        }

        uint64 snapshotBlock;
        unchecked {
            snapshotBlock = block.number.toUint64() - 1; // The snapshot block must be mined already to protect the transaction against backrunning transactions causing census changes.
        }

        (_startDate, _endDate) = _validateProposalDates(_startDate, _endDate);

        proposalId = _createProposal({
            _creator: _msgSender(),
            _metadata: _metadata,
            _startDate: _startDate,
            _endDate: _endDate,
            _actions: _actions,
            _allowFailureMap: _allowFailureMap
        });

        // Store proposal related information
        Proposal storage proposal_ = proposals[proposalId];

        proposal_.parameters.startDate = _startDate;
        proposal_.parameters.endDate = _endDate;
        proposal_.parameters.snapshotBlock = snapshotBlock;
        proposal_.parameters.votingMode = votingMode();
        proposal_.parameters.supportThreshold = supportThreshold();
        proposal_.parameters.minVotingPower = _applyRatioCeiled(
            totalVotingPower(snapshotBlock),
            minParticipation()
        );

        // Reduce costs
        if (_allowFailureMap != 0) {
            proposal_.allowFailureMap = _allowFailureMap;
        }

        for (uint256 i; i < _actions.length; ) {
            proposal_.actions.push(_actions[i]);
            unchecked {
                ++i;
            }
        }

        if (_voteOption != VoteOption.None) {
            vote(proposalId, _voteOption, _tryEarlyExecution);
        }
    }

    /// @inheritdoc IMembership
    function isMember(address _account) external view returns (bool) {
        return isListed(_account);
    }

    /// @inheritdoc MajorityVotingBase
    function _vote(
        uint256 _proposalId,
        VoteOption _voteOption,
        address _voter,
        bool _tryEarlyExecution
    ) internal override {
        Proposal storage proposal_ = proposals[_proposalId];

        VoteOption state = proposal_.voters[_voter];

        // Remove the previous vote.
        if (state == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes - 1;
        } else if (state == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no - 1;
        } else if (state == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain - 1;
        }

        // Store the updated/new vote for the voter.
        if (_voteOption == VoteOption.Yes) {
            proposal_.tally.yes = proposal_.tally.yes + 1;
        } else if (_voteOption == VoteOption.No) {
            proposal_.tally.no = proposal_.tally.no + 1;
        } else if (_voteOption == VoteOption.Abstain) {
            proposal_.tally.abstain = proposal_.tally.abstain + 1;
        }

        proposal_.voters[_voter] = _voteOption;

        emit VoteCast({
            proposalId: _proposalId,
            voter: _voter,
            voteOption: _voteOption,
            votingPower: 1
        });

        if (_tryEarlyExecution && _canExecute(_proposalId)) {
            _execute(_proposalId);
        }
    }

    // function recoverVote() public {}

    // This function receives either setWorldID or vote call
    // from remote chian via Hyperlane Messaging API.
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external override onlyMailbox {
        require(
            remoteVotingRouters[TypeCasts.bytes32ToAddress(_sender)],
            "INVALID_ORIGIN"
        );

        (
            bool _setIdOrVote,
            uint _value,
            address _sender,
            bytes memory _params
        ) = abi.decode(_data, (bool, uint, address, bytes));

        if (_setIdOrVote) {
            (
                address signal,
                uint root,
                uint nullifierHash,
                uint256[8] memory proof
            ) = abi.decode(_params, (address, uint, uint, uint[8]));
            // register
            setWorldIDFromRemote(_sender, signal, root, nullifierHash, proof);
        } else {
            (
                uint256 _proposalId,
                uint _voteOptionNum,
                address _voter,
                bool _tryEarlyExecution
            ) = abi.decode(_params, (uint256, uint, address, bool));

            IMajorityVoting.VoteOption voteOp;
            if (_voteOptionNum == 0) {
                voteOp = IMajorityVoting.VoteOption.None;
            } else if (_voteOptionNum == 1) {
                voteOp = IMajorityVoting.VoteOption.Abstain;
            } else if (_voteOptionNum == 2) {
                voteOp = IMajorityVoting.VoteOption.Yes;
            } else {
                voteOp = IMajorityVoting.VoteOption.No;
            }
        }
    }

    // function _decodeRegistrationParams(
    //     bytes memory _data
    // ) internal pure returns () {
    //     (
    //         address signal,
    //         uint root,
    //         uint nullifierHash,
    //         uint256[8] calldata proof
    //     ) = abi.decode(_data, (address, uint, uint, uint[8]));

    //     return (signal, root, nullifierHash, proof);
    // }

    /// @inheritdoc MajorityVotingBase
    function _canVote(
        uint256 _proposalId,
        address _account,
        VoteOption _voteOption
    ) internal view override returns (bool) {
        Proposal storage proposal_ = proposals[_proposalId];

        // The proposal vote hasn't started or has already ended.
        if (!_isProposalOpen(proposal_)) {
            return false;
        }

        // The voter votes `None` which is not allowed.
        if (_voteOption == VoteOption.None) {
            return false;
        }

        // The voter has no voting power.
        if (!isListedAtBlock(_account, proposal_.parameters.snapshotBlock)) {
            return false;
        }

        // The voter hasn't been verified by worldID
        if (addressToNullifier[_account] == 0) {
            return false;
        }

        // The voter has already voted but vote replacement is not allowed.
        if (
            proposal_.voters[_account] != VoteOption.None &&
            proposal_.parameters.votingMode != VotingMode.VoteReplacement
        ) {
            return false;
        }

        return true;
    }

    /// @dev This empty reserved space is put in place to allow future versions to add new
    /// variables without shifting down storage in the inheritance chain.
    /// https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
    uint256[50] private __gap;
}
