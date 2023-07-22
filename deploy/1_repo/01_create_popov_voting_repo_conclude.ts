import {getDeployedContracts} from '../../utils/helpers';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {setTimeout} from 'timers/promises';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Concluding AddresslistVotingSetup deployment.\n`);

  const {network} = hre;

  // Add a timeout for polygon because the call to `implementation()` can fail for newly deployed contracts in the first few seconds
  if (network.name === 'polygon') {
    console.log(`Waiting 30secs for ${network.name} to finish up...`);
    await setTimeout(30000);
  }

  const pluginRepo = getDeployedContracts()[network.name]['PluginRepo'];

  hre.aragonToVerifyContracts.push({
    address: pluginRepo,
    args: [],
  });
};

export default func;
func.tags = ['New', 'CreatePopovVotingRepo', 'Verify'];
