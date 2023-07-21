import addresslistBuildMetadata from '../../contracts/majority-voting/addresslist/build-metadata.json';
import addresslistReleaseMetadata from '../../contracts/majority-voting/addresslist/release-metadata.json';
import {
  networkNameMapping,
  osxContracts,
  findEventTopicLog,
  addDeployedContract,
} from '../../utils/helpers';
import {toHex} from '../../utils/ipfs-upload';
import {uploadToIPFS} from '../../utils/ipfs-upload';
import {
  PluginRepoFactory__factory,
  PluginRepoRegistry__factory,
  PluginRepo__factory,
} from '@aragon/osx-ethers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`\nCreating address-list-voting repo.`);

  console.warn(
    'Please make sure pluginRepo is not created more than once with the same name.'
  );

  const {deployments, network} = hre;
  const [deployer] = await hre.ethers.getSigners();

  let pluginRepoFactoryAddr: string =
    '0x4E7c97ab08c046A8e43571f9839d768ae84492e4';
  //osxContracts[networkNameMapping[network.name]].PluginRepoFactory;

  console.log(
    `Using the ${
      networkNameMapping[network.name]
    } PluginRepoFactory address (${pluginRepoFactoryAddr}) for deployment...`
  );

  const pluginRepoFactory = PluginRepoFactory__factory.connect(
    pluginRepoFactoryAddr,
    deployer
  );

  const addresslistReleaseCIDPath = await uploadToIPFS(
    JSON.stringify(addresslistReleaseMetadata),
    false
  );
  const addresslistBuildCIDPath = await uploadToIPFS(
    JSON.stringify(addresslistBuildMetadata),
    false
  );

  console.log(`Uploaded metadata of release 1: ${addresslistReleaseCIDPath}`);
  console.log(`Uploaded metadata of build 1: ${addresslistBuildCIDPath}`);

  const pluginName = 'address-list-voting-plugin';
  const pluginSetupContractName = 'AddresslistVotingSetup';

  const setup = await deployments.get(pluginSetupContractName);
  toHex;
  // Create Repo for Release 1 and Build 1
  const tx = await pluginRepoFactory.createPluginRepoWithFirstVersion(
    pluginName,
    setup.address,
    deployer.address,
    toHex(addresslistReleaseCIDPath),
    toHex(addresslistBuildCIDPath),
    {
      gasLimit: 1000000,
    }
  );

  const eventLog = await findEventTopicLog(
    tx,
    PluginRepoRegistry__factory.createInterface(),
    'PluginRepoRegistered'
  );
  if (!eventLog) {
    throw new Error('Failed to get PluginRepoRegistered event log');
  }

  const pluginRepo = PluginRepo__factory.connect(
    eventLog.args.pluginRepo,
    deployer
  );

  console.log(
    `"${pluginName}" PluginRepo deployed at: ${pluginRepo.address} with `
  );

  addDeployedContract(network.name, 'PluginRepo', pluginRepo.address);
  addDeployedContract(network.name, pluginSetupContractName, setup.address);
};

export default func;
func.tags = ['AddresslistVotingRepo', 'PublishAddresslistVoting'];
