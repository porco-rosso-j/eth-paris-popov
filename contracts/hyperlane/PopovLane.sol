pragma solidity ^0.8.10;

import "@hyperlane-xyz/core/contracts/interfaces/IMessageRecipient.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract PopovLane is IMessageRecipient, Initializable {
    address public mailbox;

    mapping(address => bool) public popovLaneRemotes;

    function _initializePopovLane(
        address _mailbox,
        address[] memory _popovLaneRemote
    ) internal onlyInitializing {
        mailbox = _mailbox;
        _registerPopovLaneRemotes(_popovLaneRemote);
    }

    modifier onlyMailbox() {
        require(msg.sender == mailbox);
        _;
    }

    function _registerPopovLaneRemotes(address[] memory _remotes) internal {
        for (uint i; i < _remotes.length; i++) {
            if (_remotes.length != 0) {
                require(_remotes[i] != address(0), "INVALID_ADDRESS");
            }
            popovLaneRemotes[_remotes[i]] = true;
        }
    }

    // handle == vote
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _data
    ) external virtual onlyMailbox {}
}
