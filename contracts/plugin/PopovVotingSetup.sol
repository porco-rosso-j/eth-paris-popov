// SPDX-License-Identifier: AGPL-3.0-or-later

pragma solidity 0.8.17;

import {IDAO} from "@aragon/osx/core/dao/IDAO.sol";
import {DAO} from "@aragon/osx/core/dao/DAO.sol";
import {PermissionLib} from "@aragon/osx/core/permission/PermissionLib.sol";
import {PluginSetup, IPluginSetup} from "@aragon/osx/framework/plugin/setup/PluginSetup.sol";
import {MajorityVotingBase} from "../MajorityVotingBase.sol";
import {PopovVoting} from "./PopovVoting.sol";

/// @title PopovVotingSetup
/// @author Porco Rosso
/// @notice The setup contract of the `PopovVoting` plugin.
contract PopovVotingSetup is PluginSetup {
    /// @notice The address of `PopovVoting` plugin logic contract to be used in creating proxy contracts.
    PopovVoting private immutable popovVotingBase;

    /// @notice The contract constructor, that deploys the `PopovVoting` plugin logic contract.
    constructor() {
        popovVotingBase = new PopovVoting();
    }

    /// @inheritdoc IPluginSetup
    function prepareInstallation(
        address _dao,
        bytes calldata _data
    )
        external
        returns (address plugin, PreparedSetupData memory preparedSetupData)
    {
        // Decode `_data` to extract the params needed for deploying and initializing `AddresslistVoting` plugin.
        (
            MajorityVotingBase.VotingSettings memory votingSettings,
            address[] memory members,
            address _worldID,
            string memory _appId,
            string memory _actionId
        ) = abi.decode(
                _data,
                (
                    MajorityVotingBase.VotingSettings,
                    address[],
                    address,
                    string,
                    string
                )
            );

        // Prepare and Deploy the plugin proxy.
        plugin = createERC1967Proxy(
            address(popovVotingBase),
            abi.encodeWithSelector(
                PopovVoting.initialize.selector,
                _dao,
                votingSettings,
                members,
                _worldID,
                _appId,
                _actionId
            )
        );

        // Prepare permissions
        PermissionLib.MultiTargetPermission[]
            memory permissions = new PermissionLib.MultiTargetPermission[](4);

        // Set permissions to be granted.
        // Grant the list of permissions of the plugin to the DAO.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            popovVotingBase.UPDATE_ADDRESSES_PERMISSION_ID()
        );

        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            popovVotingBase.UPDATE_VOTING_SETTINGS_PERMISSION_ID()
        );

        permissions[2] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            popovVotingBase.UPGRADE_PLUGIN_PERMISSION_ID()
        );

        // Grant `EXECUTE_PERMISSION` of the DAO to the plugin.
        permissions[3] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Grant,
            _dao,
            plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );

        preparedSetupData.permissions = permissions;
    }

    /// @inheritdoc IPluginSetup
    function prepareUninstallation(
        address _dao,
        SetupPayload calldata _payload
    )
        external
        view
        returns (PermissionLib.MultiTargetPermission[] memory permissions)
    {
        // Prepare permissions
        permissions = new PermissionLib.MultiTargetPermission[](4);

        // Set permissions to be Revoked.
        permissions[0] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            popovVotingBase.UPDATE_ADDRESSES_PERMISSION_ID()
        );

        permissions[1] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            popovVotingBase.UPDATE_VOTING_SETTINGS_PERMISSION_ID()
        );

        permissions[2] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _payload.plugin,
            _dao,
            PermissionLib.NO_CONDITION,
            popovVotingBase.UPGRADE_PLUGIN_PERMISSION_ID()
        );

        permissions[3] = PermissionLib.MultiTargetPermission(
            PermissionLib.Operation.Revoke,
            _dao,
            _payload.plugin,
            PermissionLib.NO_CONDITION,
            DAO(payable(_dao)).EXECUTE_PERMISSION_ID()
        );
    }

    /// @inheritdoc IPluginSetup
    function implementation() external view returns (address) {
        return address(popovVotingBase);
    }
}
