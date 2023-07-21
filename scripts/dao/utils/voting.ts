import {ethers} from 'ethers';

export enum VotingMode {
  Standard,
  EarlyExecution,
  VoteReplacement,
}

const RATIO_BASE = ethers.BigNumber.from(10).pow(6); // 100% => 10**6
export const pctToRatio = (x: number) => RATIO_BASE.mul(x).div(100);
export const ONE_HOUR = 60 * 60;
