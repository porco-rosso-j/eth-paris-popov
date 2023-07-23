// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;

import "@hyperlane-xyz/core/contracts/interfaces/IMailbox.sol";
import "@hyperlane-xyz/core/contracts/interfaces/IInterchainGasPaymaster.sol";
import {TypeCasts} from "@hyperlane-xyz/core/contracts/libs/TypeCasts.sol";

contract PopovLaneRemote {
    using TypeCasts for address;
    using TypeCasts for bytes;

    IMailbox public mailbox;
    IInterchainGasPaymaster public igp;
    address public popov;

    constructor(
        address _mailbox,
        address _interchainGasPaymaster,
        address _popov // plugin proxy
    ) {
        mailbox = IMailbox(_mailbox);
        igp = IInterchainGasPaymaster(_interchainGasPaymaster);
        popov = _popov;
    }

    function registerFromRemote(
        uint32 _destinationDomain,
        uint _gasVal,
        uint _gasAmt,
        address _signal,
        uint _root,
        uint _nullifierHash,
        uint256[8] memory _proof
    ) public {
        //             ["address", "uint", "uint", "uint[8]"],
        bytes memory _params = abi.encode(
            msg.sender,
            _signal,
            _root,
            _nullifierHash,
            _proof
        );

        bytes memory params = abi.encode(true, _params);

        dispatchAndPayGas(_destinationDomain, _gasVal, _gasAmt, params);
    }

    function voteFromRemote(
        uint32 _destinationDomain,
        uint _gasVal,
        uint _gasAmt,
        uint256 _proposalId,
        uint _voteOptionNum,
        bool _tryEarlyExecution
    ) public {
        //           ["uint", "uint", "address", "bool"],
        bytes memory _params = abi.encode(
            _proposalId,
            msg.sender,
            _voteOptionNum,
            _tryEarlyExecution
        );

        bytes memory params = abi.encode(false, _params);

        dispatchAndPayGas(_destinationDomain, _gasVal, _gasAmt, params);
    }

    function dispatchAndPayGas(
        uint32 _destinationDomain,
        uint _gasVal,
        uint _gasAmt,
        bytes memory _params
    ) internal {
        bytes32 messageId = mailbox.dispatch(
            _destinationDomain,
            TypeCasts.addressToBytes32(popov),
            _params
        );

        igp.payForGas{value: _gasVal}(
            messageId, // The ID of the message that was just dispatched
            _destinationDomain, // The destination domain of the message
            _gasAmt,
            address(this) // refunds are returned to this contract
        );
    }

    function getGasPayment(
        uint32 _destDomain,
        uint _gasAmt
    ) public view returns (uint) {
        return igp.quoteGasPayment(_destDomain, _gasAmt);
    }

    function withdraw() public {
        msg.sender.call{value: address(this).balance}("");
    }

    receive() external payable {}
}
