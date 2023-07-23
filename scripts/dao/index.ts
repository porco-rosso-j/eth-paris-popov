import {Context, ContextParams} from '@aragon/sdk-client';
import {SupportedNetwork} from '@aragon/sdk-client-common';
import {Wallet} from '@ethersproject/wallet';
import * as dotenv from 'dotenv';
import * as ethers from 'ethers';

dotenv.config();

// Set up your IPFS API key. You can get one either by running a local node or by using a service like Infura or Alechmy.
// Make sure to always keep these private in a file that is not committed to your public repository.
const IPFS_API_KEY: string = process.env.infura_api_key as string;
// export const rpc = ('https://polygon-mumbai.g.alchemy.com/v2/' +
//   process.env.ALCHEMY_MUMBAI_KEY) as string;
export const rpc = ('https://eth-goerli.g.alchemy.com/v2/' +
  process.env.ALCHEMY_GOERLI_KEY) as string;
export const dev_pk = process.env.PRIVATE_KEY as string;
export const dev_pk2 = process.env.PRIVATE_KEY2 as string;

// OPTION A: The simplest ContextParams you can have is this. This uses our default values and should work perfectly within your product.
const minContext: ContextParams = {
  // Choose the network you want to use. You can use "goerli" (Ethereum) or "maticmum" (Polygon) for testing, or "mainnet" (Ethereum) and "polygon" (Polygon) for mainnet.
  network: SupportedNetwork.MUMBAI,
  web3Providers: [rpc],
  // This is the signer account who will be signing transactions for your app. You can use also use a specific account where you have funds, through passing it `new Wallet("your-wallets-private-key")` or pass it in dynamically when someone connects their wallet to your dApp.
  signer: new Wallet(dev_pk, ethers.getDefaultProvider(rpc)),

  ipfsNodes: [
    {
      url: 'https://test.ipfs.aragon.network/api/v0',
      //url: "https://ipfs.infura.io:5001",
      headers: {
        'X-API-KEY': IPFS_API_KEY || 'b477RhECf8s8sdM7XrkLBs2wHc4kCMwpbcFC55Kt',
      },
    },
  ],
};

export const context: Context = new Context(minContext);
