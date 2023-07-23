import popovBuildMetadata from '../../contracts/plugin/build-metadata.json';
import popovReleaseMetadata from '../../contracts/plugin/release-metadata.json';
import {
  networkNameMapping,
  findEventTopicLog,
  addDeployedContract,
} from '../../utils/helpers';
import {uploadToIPFS, toHex} from '../../utils/ipfs-upload';
import {
  PluginRepoFactory__factory,
  PluginRepoRegistry__factory,
  PluginRepo__factory,
} from '@aragon/osx-ethers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`\nCreating popov-voting repo.`);

  const {deployments, network} = hre;
  const [deployer] = await hre.ethers.getSigners();

  let pluginRepoFactoryAddr: string = "0x477EB3b39C92c38B43778266b09471285e0F7808"
    // '0x4E7c97ab08c046A8e43571f9839d768ae84492e4'; // mumbai
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

  const popovReleaseCIDPath = await uploadToIPFS(
    JSON.stringify(popovReleaseMetadata),
    false
  );
  const popovBuildCIDPath = await uploadToIPFS(
    JSON.stringify(popovBuildMetadata),
    false
  );

  console.log(`Uploaded metadata of release 1: ${popovReleaseCIDPath}`);
  console.log(`Uploaded metadata of build 1: ${popovBuildCIDPath}`);

  const pluginName = 'popov-voting-plugin1'; // shouln't be same as previous ones
  const pluginSetupContractName = 'PopovVotingSetup';

  const setup = await deployments.get(pluginSetupContractName);
  toHex;
  // Create Repo for Release 1 and Build 1
  const tx = await pluginRepoFactory.createPluginRepoWithFirstVersion(
    pluginName,
    setup.address,
    deployer.address,
    toHex(popovReleaseCIDPath),
    toHex(popovBuildCIDPath),
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
func.tags = ['PopovVotingRepo', 'PublishPopovVoting'];
