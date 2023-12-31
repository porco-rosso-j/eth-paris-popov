import metadata from '../../contracts/plugin/build-metadata.json';
import {context} from './index';
import {getDaoMetadata} from './utils/ipfs-metadata';
import {VotingMode, pctToRatio, ONE_HOUR} from './utils/voting';
import artifacts, {activeContractsList} from '@aragon/osx-artifacts';
import {Client} from '@aragon/sdk-client';
import {getNamedTypesFromMetadata} from '@aragon/sdk-client-common';
import {ethers} from 'ethers';

const pluginSetUpRepo = '0x908F5FfBbBD4000f788865459Bdf37734cd56ea6'; // Popov Imp
const mailbox = "0xCC737a94FecaeC165AbCf12dED095BB13F037685";
const popovLaneRemotes:string[] = [];

async function createDAO() {
  const client: Client = new Client(context);
  const daoName: string = 'TestDAO';

  const metaData = await getDaoMetadata(daoName);

  const daoSetting = {
    trustedForwarder: ethers.constants.AddressZero,
    daoURI: '',
    subdomain: '',
    metadata: metaData, //
  };

  const votingSettings = {
    votingMode: VotingMode.EarlyExecution,
    supportThreshold: pctToRatio(50), // 50%
    minParticipation: pctToRatio(20), // 20%
    minDuration: ONE_HOUR,
    minProposerVotingPower: 1,
  };

  const dao_members = [
    '0x91A399E2F7B768e627f1f7Aff2Df88bA73813911',
    '0xAB256C9d6aAE9ee6118A1531d43751996541799D',
    '0x3cad9f430c5e9b29C7F9C7Bc7D3b06f144B0A2fF',
  ];

    //const WorldIDRouter = "0x719683F13Eeea7D84fCBa5d7d17Bf82e03E3d260" // mumbai
    const WorldIDRouter = "0x05C4AE6bC33e6308004a47EbFa99E5Abb4133f86" // goerli
    const NEXT_PUBLIC_WLD_APP_ID = "app_staging_7cae3c105dab762df86776e7d30bc5c8" // popov2
    const NEXT_PUBLIC_WLD_ACTION_NAME = "verify"

  const _data = ethers.utils.defaultAbiCoder.encode(
    getNamedTypesFromMetadata(metadata.pluginSetup.prepareInstallation.inputs),
    [
      Object.values(votingSettings), 
      dao_members, 
      WorldIDRouter,
      NEXT_PUBLIC_WLD_APP_ID, 
      NEXT_PUBLIC_WLD_ACTION_NAME,
      mailbox,
      popovLaneRemotes
    ]
  );

  console.log("_data: ", _data)

  const pluginSetting = {
    pluginSetupRef: {
      versionTag: {
        release: 1,
        build: 1,
      },
      pluginSetupRepo: pluginSetUpRepo,
    },
    data: _data,
  };

  let pluginSettings: any[] = [];
  pluginSettings.push(pluginSetting);


  // create daoFacotry Contract Instance
  const daoFactory = new ethers.Contract(
    activeContractsList.goerli.DAOFactory,
    artifacts.DAOFactory.abi,
    client.web3.getSigner()
  );

  //console.log("DAO Addr: ", await getDAOAddress(daoFactory, daoSetting, pluginSettings))

  // create DAO
  const tx = await (
    await daoFactory.createDao(daoSetting, pluginSettings, {
      gasLimit: 2000000,
    })
  ).wait();
  console.log('tx: ', tx.transactionHash);
}

createDAO().catch(error => {
  console.error(error);
  process.exitCode = 1;
});

// async function getDAOAddress(
//   daoFactory: ethers.Contract, 
//   _daoSetting: any,
//   _pluginSettings: any
//   ):Promise<string> {

//   const daoAddr = await daoFactory.callStatic.createDAO(_daoSetting, _pluginSettings);
//   return daoAddr
// }
