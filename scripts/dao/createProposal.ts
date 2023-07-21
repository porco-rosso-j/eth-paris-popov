import {context} from './index';
import {getProposalMetadata} from './utils/ipfs-metadata';
import artifacts from '@aragon/osx-artifacts';
import {Client, VoteValues} from '@aragon/sdk-client';
import {ethers} from 'ethers';

// const DAOAddress = '0x528225540aADB9c9aAfFdf1E89CF2630FA7FeCe5';
const PluginAddress = '0x3d402c0ec82c563a3fca2307ef497dfb29399461';

async function createProposal() {
  const client: Client = new Client(context);

  const proposalMetadata = await getProposalMetadata();

  // create contract instance
  const addressListVoting = new ethers.Contract(
    PluginAddress,
    artifacts.AddresslistVoting.abi,
    client.web3.getSigner()
  );

  // get next proposal Id
  const proposalId = await getProposalId(addressListVoting);

  // create Proposal
  const tx = await (
    await addressListVoting.createProposal(
      proposalMetadata,
      [],
      1,
      0,
      0,
      VoteValues.YES,
      true,
      {
        gasLimit: 300000,
      }
    )
  ).wait();
  console.log('tx: ', tx.transactionHash);

  // view the created proposal
  const proposal = await addressListVoting.getProposal(proposalId);
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
  addressListVoting: ethers.Contract
): Promise<number> {
  const id = await addressListVoting.callStatic.createProposal(
    Buffer.from('0x00'),
    [],
    1,
    0,
    0,
    VoteValues.YES,
    true
  );
  //console.log('id: ', id);
  return id;
}
