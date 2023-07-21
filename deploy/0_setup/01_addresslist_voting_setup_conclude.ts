import {
  AddresslistVoting__factory,
  AddresslistVotingSetup__factory,
} from '../../typechain';
import {DeployFunction} from 'hardhat-deploy/types';
import {HardhatRuntimeEnvironment} from 'hardhat/types';
import {setTimeout} from 'timers/promises';

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  console.log(`Concluding addresslist voting setup deployment.\n`);
  const {deployments, network, ethers} = hre;
  const [deployer] = await ethers.getSigners();

  const setupDeployment = await deployments.get('AddresslistVotingSetup');
  const setup = AddresslistVotingSetup__factory.connect(
    setupDeployment.address,
    deployer
  );
  const implementation = AddresslistVoting__factory.connect(
    await setup.implementation(),
    deployer
  );

  // add a timeout for polygon because the call to `implementation()` can fail for newly deployed contracts in the first few seconds
  if (network.name === 'polygon') {
    console.log(`Waiting 30secs for ${network.name} to finish up...`);
    await setTimeout(30000);
  }

  hre.aragonToVerifyContracts.push({
    address: setupDeployment.address,
    args: setupDeployment.args,
  });
  hre.aragonToVerifyContracts.push({
    address: implementation.address,
    args: [],
  });
};

export default func;
func.tags = ['New', 'AddresslistVotingSetup', 'Verify'];
