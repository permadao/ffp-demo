A demo to use javascript ffp(FusionFi Protocol) sdk.

FusionFi is a unified financial protocol on permaweb(ao). Powered by [everVision Labs](https://ever.vision).

With ffp, you can quickly implement various financial scenarios, including but not limited to: exchanges, lending, futures, and even stablecoins. If you're an application developer, you can seamlessly integrate ffp into your games and social apps. Using ffp, all processes on ao can achieve seamless financial business integration.

Read more, [Intelligent Finance: From AgentFi to FusionFi, Exploring AI-Driven Financial Models on AO](https://x.com/outprog_ar/status/1800907057740095713).

## Install

Integrate ffp into your project.

```bash
npm install aoffp
```

* [Prepare](#prepare)
  * [0. install](#0-install)
  * [1. Set up config](#1-set-up-config)
  * [2. Get token airdrop](#2-get-token-airdrop)
* [Use Case](#use-case)
  * [Agent](#agent)
    * [1. Create your agent](#1-create-your-agent)
    * [2. Deposit token to your agent](#2-deposit-token-to-your-agent)
  * [Orderbook](#orderbook)
    * [1. Create your orderbook agent](#1-create-your-orderbook-agent)
    * [2. Deposit token to your orderbook agent](#2-deposit-token-to-your-orderbook-agent)
    * [3. Make order](#3-make-order)
    * [4. use agent1 to take order](#4-use-agent1-to-take-order)
  * [AMM](#amm)
    * [1. Create your AMM agent](#1-create-your-amm-agent)
    * [2. Deposit token to your AMM agent](#2-deposit-token-to-your-amm-agent)
    * [3. Add liquidity](#3-add-liquidity)
    * [4. make an AMM order from AMM agent](#4-make-an-amm-order-from-amm-agent)
    * [5. take this order by agent](#5-take-this-order-by-agent)
    * [6. Arbitrage with orderbook order and AMM agent](#6-arbitrage-with-orderbook-order-and-amm-agent)
    * [7. Remove liquidity from AMM agent](#7-remove-liquidity-from-amm-agent)

## Prepare

### 0. install

```bash
npm install
# or
yarn install
```

### 1. Set up config

Generate some new wallets for test.

```bash
mkdir wallets
node ./generate.js
```

Set up `WALLET1` & `WALLET2` environment variables from `.env.local` file.

```bash
export $(cat .env.local | xargs)
```

### 2. Get token airdrop

We set $HELLO & $KITTY token for test, you can get those tokens by `airdrop.js`.

```bash
node ./airdrop.js
```

When this flow is done, you can check the balance:

```bash
node ./balance.js --address=$WALLET1
```

Output:

```
address: wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM
$HELLO balance  100000000000000
$KITTY balance  100000000000000
```

This will be the same for `WALLET2`.

## Use Case

Next, we will introduce the use cases of ffp, including orderbook, AMM, and lending.

From beggining, you should create your first agent using the following example.

### Agent

#### 1. Create your agent

```bash
node ./agent/create.js
```

Output:

```
wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM create agent: <YourAgent1>
ORHaLUrAiknTAq2Wszoyl6buJrd3MqDKLTF_2CggLtw create agent: <YourAgent2>
```

Set up `AGENT1` & `AGENT2` environment variables from `.env.local` file.

```bash
export $(cat .env.local | xargs)
```

#### 2. Deposit token to your agent

Deposit into your agent.

```bash
node ./agent/deposit.js --walletN=1 --agentId=$AGENT1
```

If you will check balances in your agent:

```bash
node ./balance.js --address=$AGENT1
```

Do the same for the second agent.

```bash
node ./agent/deposit.js --walletN=2 --agentId=$AGENT2
node ./balance.js --address=$AGENT2
```

Good job! You already created two agents. You can try Orderbook agent or AMM agent now. If you want to try AMM agent, you can skip the orderbook section.

### Orderbook

#### 1. Create your orderbook agent

```bash
node ./orderbook/create.js
```

Output:

```
wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM create orderbook agent: <YourOrderBookAgent1>
ORHaLUrAiknTAq2Wszoyl6buJrd3MqDKLTF_2CggLtw create orderbook agent: <YourOrderBookAgent2>
```

Set up `ORDERBOOKAGENT1` & `ORDERBOOKAGENT2` environment variables from `.env.local` file.

```bash
export $(cat .env.local | xargs)
```

#### 2. Deposit token to your orderbook agent

Deposit into your orderbook.

```bash
node ./orderbook/deposit.js --walletN=2 --agentId=$ORDERBOOKAGENT2
```

If you will check balances in your agent:

```bash
node ./balance.js --address=$ORDERBOOKAGENT2
```

#### 3. Make order

We use the first one agent to create a new order.

Run make.js

```bash
node ./orderbook/make.js --walletN=2 --agentId=$ORDERBOOKAGENT2
```

Output:

```
make order MsgId iZzNQW0nem81JlgNk3fm1TXmwtK2mq2lwBoDvALeguM
openOrders [
  {
    ID: 1,
    HolderAssetID: '4557tfvtAlS8WS0-KF0sGdfgy6An2dcVXQUGocrKV7U',
    HolderAmount: '3',
    NoteID: '<NoteID>',
    Issuer: '8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw',
    Type: 'Orderbook',
    AssetID: '-v4cUCUcRiJH67jPMUt-Uhn-K4PHxrkoySM2uqAjAF0',
    IssueDate: 1726236373254,
    Status: 'Open',
    Amount: '1'
  }
]
```

If no orders output, you can use the following command for querying.

```bash
node ./orderbook/query.js --agentId=$ORDERBOOKAGENT2
```

Set the `NoteID` to env variable.

```bash
export NOTEID=<NoteID>
```

#### 4. use agent1 to take order

Run

```bash
node ./agent/take.js --walletN=1 --agentId=$AGENT1 --noteId=$NOTEID
```

After transaction done, the balances of both agents have been updated, and the transaction is complete.

```bash
node ./balance.js --address=$AGENT1
node ./balance.js --address=$ORDERBOOKAGENT2
```

### AMM

#### 1. Create your AMM agent

```bash
node ./amm/create.js
```

Output:

```
wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM create amm agent: <YourAMMAgent1>
ORHaLUrAiknTAq2Wszoyl6buJrd3MqDKLTF_2CggLtw create amm agent: <YourAMMAgent2>
```

Set up `AMMAGENT1` & `AMMAGENT2` environment variables from `.env.local` file.

```bash
export $(cat .env.local | xargs)
```

#### 2. Deposit token to your AMM agent

Deposit into your AMM agent

```bash
node ./amm/deposit.js --walletN=2 --agentId=$AMMAGENT2
```

If you will check balances in your agent:

```bash
node ./balance.js --address=$AMMAGENT2
```

#### 3. Add liquidity

add deposited token to your AMM liquidity pool

```bash
node ./amm/addLiquidity.js --walletN=2 --agentId=$AMMAGENT2
```

If you will query agent info:

```bash
node ./amm/query.js --walletN=2 --agentId=$AMMAGENT2
```

#### 4. make an AMM order from AMM agent

```bash
node ./amm/request.js --walletN=2 --agentId=$AMMAGENT2
```

Output:

```js
{
  Type: 'Orderbook',
  Status: 'Open',
  AssetID: '4557tfvtAlS8WS0-KF0sGdfgy6An2dcVXQUGocrKV7U',
  MakeTx: 'KPo-27zTIYCZYqgzyeLC8FkmXuZf7WnRZWQr8fcWLMI',
  HolderAssetID: '-v4cUCUcRiJH67jPMUt-Uhn-K4PHxrkoySM2uqAjAF0',
  HolderAmount: '10',
  NoteID: '7dGsvqEY-Ler2aljBP2Fk5X1Aeb8TAPF9vI2SEVIOfU',
  ExpireDate: 1729069364728,
  IssueDate: 1729069274728,
  Amount: '2'
}
```

Set the `NoteID` to env variable.

```bash
export NOTEID=<NoteID>
```

#### 5. take this order by agent

Run

```bash
node ./agent/take.js --walletN=1 --agentId=$AGENT1 --noteId=$NOTEID
```

After transaction done, the balances of both agents have been updated, and the transaction is complete.

```bash
node ./balance.js --address=$AGENT1

node ./amm/query.js --walletN=2 --agentId=$AMMAGENT2
```

#### 6. Arbitrage with orderbook order and AMM agent

```bash
node ./arbitrage.js --agentId=$AGENT1 --orderbookAgentId=$ORDERBOOKAGENT2 --ammAgentId=$AMMAGENT2
```

#### 7. Remove liquidity from AMM agent

```bash
node ./amm/removeLiquidity.js --walletN=2 --agentId=$AMMAGENT2
```
