import {rpc, dev_pk2} from './index';
import artifacts from '@aragon/osx-artifacts';
import {VoteValues} from '@aragon/sdk-client';
import {ethers} from 'ethers';
import deployedContracts from "../../deployed_contracts.json"

const PluginAddress = deployedContracts.polygonMumbai.PluginProxy;

async function vote() {
  // wallet is the second member of the DAO
  const wallet: ethers.Wallet = new ethers.Wallet(
    dev_pk2,
    ethers.getDefaultProvider(rpc)
  );

  const addressListVoting = new ethers.Contract(
    PluginAddress,
    artifacts.AddresslistVoting.abi,
    wallet
  );

  const proposalId = 0;

  const tx = await (
    await addressListVoting.vote(proposalId, VoteValues.YES, true, {
      gasLimit: 300000,
    })
  ).wait();
  console.log('tx: ', tx.transactionHash);

  const proposal = await addressListVoting.getProposal(proposalId);
  console.log('proposal Id: ', proposalId);
  console.log('open: ', proposal.open); // should be false
  console.log('executed: ', proposal.executed); // should be true
  console.log('parameters: ', proposal.parameters);
  console.log('tally: ', proposal.tally);
  console.log('actions: ', proposal.actions);
  console.log('allowFailureMap: ', proposal.allowFailureMap);
}

vote().catch(error => {
  console.error(error);
  process.exitCode = 1;
});
