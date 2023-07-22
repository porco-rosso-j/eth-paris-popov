pragma solidity ^0.8.10;

import "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PopovLane is IMessageRecipient, Initializable {
    address public mailbox;

    mapping(address => bool) public remoteVotingRouters;

    function _initializePopovLane(
        address _mailbox,
        address[] memory _remoteVotingRouters
    ) internal onlyInitializing {
        mailbox = _mailbox;
        _registerRemoteVotingRouters(_remoteVotingRouters);
    }

    modifier onlyMailbox() {
        require(msg.sender == mailbox);
        _;
    }

    function _registerRemoteVotingRouters(address[] memory _routers) internal {
        for (uint i; i < _routers.length; i++) {
            require(_routers[i] != address(0), "INVALID_ADDRESS");
            remoteVotingRouters[_routers[i]] = true;
        }
    }

    // handle == vote
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external virtual onlyMailbox {}
}
