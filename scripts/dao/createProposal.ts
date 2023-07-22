import {context} from './index';
import {getProposalMetadata} from './utils/ipfs-metadata';
import artifacts from '@aragon/osx-artifacts';
import {Client, VoteValues} from '@aragon/sdk-client';
import {ethers} from 'ethers';

const PluginAddress = "0x6b27a9162d93bb13cdb730efcb696a21167e7952";

async function createProposal() {
  const client: Client = new Client(context);

  const proposalMetadata = await getProposalMetadata();

  // create contract instance
  const popovVoting = new ethers.Contract(
    PluginAddress,
    artifacts.AddresslistVoting.abi,
    client.web3.getSigner()
  );

  // get next proposal Id
  const proposalId = await getProposalId(popovVoting);

  // create Proposal
  const tx = await (
    await popovVoting.createProposal(
      proposalMetadata,
      [],
      1,
      0,
      0,
      //VoteValues.YES,
      0,
      true,
      {
        gasLimit: 300000,
      }
    )
  ).wait();
  console.log('tx: ', tx.transactionHash);

  // view the created proposal
  const proposal = await popovVoting.getProposal(proposalId);
  console.log('proposal Id: ', proposalId);
  console.log('open: ', proposal.open); // should be true
  console.log('executed: ', proposal.executed); // should be false
  console.log('parameters: ', proposal.parameters);
  console.log('tally: ', proposal.tally);
  console.log('actions: ', proposal.actions);
  console.log('allowFailureMap: ', proposal.allowFailureMap);
}

createProposal().catch(error => {
  console.error(error);
  process.exitCode = 1;
});

async function getProposalId(
  popovVoting: ethers.Contract
): Promise<number> {
  const id = await popovVoting.callStatic.createProposal(
    Buffer.from('0x00'),
    [],
    1,
    0,
    0,
    //VoteValues.YES,
    0,
    true
  );
  //console.log('id: ', id);
  return id;
}
