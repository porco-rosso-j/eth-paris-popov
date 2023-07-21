import {Client, DaoMetadata} from '@aragon/sdk-client';
import {ProposalMetadata} from '@aragon/sdk-client-common';
import ipfs from 'ipfs-http-client';

export async function getDaoMetadata(_name: string): Promise<Buffer> {
  const daoMetadata: DaoMetadata = {
    name: _name,
    description: 'This is a description',
    avatar: '',
    links: [
      {
        name: 'test',
        url: 'http://...',
      },
    ],
  };

  // const metadataUri: string = await client.methods.pinMetadata(daoMetadata);
  return Buffer.from(await uploadToIPFS(JSON.stringify(daoMetadata), true));
}

export async function getProposalMetadata(): Promise<Buffer> {
  const metadata: ProposalMetadata = {
    title: 'Test Proposal',
    summary: 'This is a short description',
    description: 'This is a long description',
    resources: [
      {
        name: 'Discord',
        url: 'https://discord.com/...',
      },
      {
        name: 'Website',
        url: 'https://website...',
      },
    ],
    media: {
      logo: 'https://...',
      header: 'https://...',
    },
  };

  return Buffer.from(await uploadToIPFS(JSON.stringify(metadata), true));
}

async function uploadToIPFS(
  content: string,
  testing: boolean = true
): Promise<string> {
  const client = ipfs.create({
    url: testing
      ? 'https://testing-ipfs-0.aragon.network/api/v0'
      : 'https://ipfs-0.aragon.network/api/v0',
    headers: {
      'X-API-KEY': 'b477RhECf8s8sdM7XrkLBs2wHc4kCMwpbcFC55Kt',
    },
  });

  const cid = await client.add(content);
  await client.pin.add(cid.cid);
  return cid.path;
}
