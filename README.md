# eth-paris-popov

Fair and user-friendly on-chain voting for local DAOs/communities.
https://ethglobal.com/events/paris2023

## Deployments

#### Set-up
```shell
cp .env.example .env
```

and set PRIVATE_KEY and ALCHEMY_MUMBAI_KEY.
Then, proceed with installing dependencies:
```shell
$ yarn install
```

#### Compile
Compile the smart contracts with Hardhat:
```shell
$ yarn compile
```

Compile the smart contracts and generate TypeChain bindings:
```shell
$ yarn typechain
```

#### Deploy
deploy PopovVoting Plugin
```shell
$ yarn deploy --network polygonMumbai
```
deploy a DAO that integrates the PopovVoting Plugin
```shell
$ ts-node scripts/createDAO.ts
```
create a proposal to the DAO via the PopovVoting Plugin
```shell
$ ts-node scripts/createProposal.ts
```
cast a vote on the proposal.
```shell
$ ts-node scripts/vote.ts
```
