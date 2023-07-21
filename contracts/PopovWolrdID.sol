pragma solidity ^0.8.10;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";

import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PopovWolrdID is Initializable {
    using ByteHasher for bytes;

    /// @notice Thrown when attempting to reuse a nullifier
    error InvalidNullifier();

    /// @dev The World ID instance that will be used for verifying proofs
    IWorldID internal worldId;

    /// @dev The contract's external nullifier hash
    uint256 internal externalNullifier;

    /// @dev The World ID group ID (always 1)
    uint256 internal immutable groupId = 1;
    // uint256 internal immutable groupId = 0;

    /// @dev Whether a nullifier hash has been used already. Used to guarantee an action is only performed once by a single person
    mapping(uint256 => bool) internal nullifierHashes;
    mapping(address => uint) public addressToNullifier; // account => nullifier
    mapping(uint => address) public nullifierToAddress; // nullifier => account

    function _initializeWoldID(
        IWorldID _worldId,
        string memory _appId,
        string memory _actionId
    ) internal onlyInitializing {
        worldId = _worldId;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
    }

    /// @param signal An arbitrary input from the user, usually the user's wallet address (check README for further details)
    /// @param root The root of the Merkle tree (returned by the JS widget).
    /// @param nullifierHash The nullifier hash for this proof, preventing double signaling (returned by the JS widget).
    /// @param proof The zero-knowledge proof that demonstrates the claimer is registered with World ID (returned by the JS widget).
    /// @dev Feel free to rename this method however you want! We've used `claim`, `verify` or `execute` in the past.
    function setWorldID(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        // First, we make sure this person hasn't done this before
        if (nullifierHashes[nullifierHash]) revert InvalidNullifier();

        require(
            addressToNullifier[msg.sender] == 0 &&
                nullifierToAddress[nullifierHash] == address(0),
            "INVALID_REGISTRATION"
        );

        // We now verify the provided proof is valid and the user is verified by World ID
        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );

        nullifierHashes[nullifierHash] = true;
        addressToNullifier[msg.sender] = nullifierHash;
        nullifierToAddress[nullifierHash] = msg.sender;
    }

    // function setWorldIDFromRemote() public;

    // function recover() public ;　// + called from recoverVote() in PopovVotingPlugin

    // function addBackUpAddress() public;
}
