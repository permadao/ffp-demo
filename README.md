A demo to use javascript ffp(FusionFi Protocol) sdk.

FusionFi is a unified financial protocol on permaweb(ao). Powered by [everVision Labs](https://ever.vision).

With ffp, you can quickly implement various financial scenarios, including but not limited to: exchanges, lending, futures, and even stablecoins. If you're an application developer, you can seamlessly integrate ffp into your games and social apps. Using ffp, all processes on ao can achieve seamless financial business integration.

Read more, [Intelligent Finance: From AgentFi to FusionFi, Exploring AI-Driven Financial Models on AO](https://x.com/outprog_ar/status/1800907057740095713).

* [Prepare](#prepare)
  * [0. install](#0-install)
  * [1. Set up config](#1-set-up-config)
  * [2. Get token airdrop](#2-get-token-airdrop)
* [Use Case](#use-case)
  * [Basic](#agent)
    * [1. Create your basic agent](#1-create-your-basic-agent)
    * [2. Deposit token to your agent](#2-deposit-token-to-your-agent)
  * [Orderbook](#orderbook)
    * [1. Create your orderbook agent](#1-create-your-orderbook-agent)
    * [2. Deposit token to your orderbook agent](#2-deposit-token-to-your-orderbook-agent)
    * [3. Make order](#3-make-order)
    * [4. use agent1 to take order](#4-use-agent1-to-take-order)
  * [AMM](#amm)
    * [1. Create your AMM agent](#1-create-your-amm-agent)
    * [2. Deposit token to your AMM agent](#2-deposit-token-to-your-amm-agent)
    * [3. Add Pool](#3-add-pool)
    * [4. make an AMM order from AMM agent](#4-make-an-amm-order-from-amm-agent)
    * [5. take this order by agent](#5-take-this-order-by-agent)
    * [6. Arbitrage with orderbook order and AMM agent](#6-arbitrage-with-orderbook-order-and-amm-agent)

## Prepare

### 0. install

Integrate ffp into your project.

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

Next, we will introduce the use cases of f f p, including orderbook, AMM, and lending.

### Basic

#### 1. Create your basic agent

```bash
node ./basic/create.js
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

Deposit into your agent

```bash
node ./basic/deposit.js --walletN=1 --agentId=$AGENT1
```

If you will check balances in your agent:

```bash
node ./balance.js --address=$AGENT1
```

Do the same for the second agent.

```bash
node ./basic/deposit.js --walletN=2 --agentId=$AGENT2
node ./balance.js --address=$AGENT2
```

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

Deposit into your orderbook

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
openOrders {
  MVBggDjYkl3UxoHRZ2rO6ZLDcN4ax4Af6rehyYJ3CH0: {
    ID: 2600,
    AssetID: 'AttsQGi4xgSOTeHM6CNgEVxlrdZi4Y86LQCF__p4HUM',
    HolderAssetID: '0fLIp-xxRnQ8Nk-ruq8SBY8icaIvZMujnqCGU79fnM0',
    NoteID: 'MVBggDjYkl3UxoHRZ2rO6ZLDcN4ax4Af6rehyYJ3CH0',
    IssueDate: 1733297306962,
    HolderAmount: '3',
    Amount: '1',
    Status: 'Open',
    Price: 3,
    Issuer: 'RPFQd69SX2tbrtNBfVxzVSt9zQYk07WrHOCDhxDHu0o'
  }
}
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
node ./basic/take.js --walletN=1 --agentId=$AGENT1 --noteId=$NOTEID
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

#### 3. Add Pool

add deposited token to your AMM liquidity pool

```bash
node ./amm/addPool.js --walletN=2 --agentId=$AMMAGENT2
```

If you will query agent pool info:

```bash
node ./amm/query.js --walletN=2 --agentId=$AMMAGENT2
```

Output:

```
pools {
  "0fLIp-xxRnQ8Nk-ruq8SBY8icaIvZMujnqCGU79fnM0:AttsQGi4xgSOTeHM6CNgEVxlrdZi4Y86LQCF__p4HUM": {
    "py": "50",
    "algo": "UniswapV2",
    "fee": 30,
    "px": "50",
    "y": "AttsQGi4xgSOTeHM6CNgEVxlrdZi4Y86LQCF__p4HUM",
    "balances": {
      "0fLIp-xxRnQ8Nk-ruq8SBY8icaIvZMujnqCGU79fnM0": "50",
      "AttsQGi4xgSOTeHM6CNgEVxlrdZi4Y86LQCF__p4HUM": "50"
    },
    "x": "0fLIp-xxRnQ8Nk-ruq8SBY8icaIvZMujnqCGU79fnM0"
  }
}
```

#### 4. make an AMM order from AMM agent

```bash
node ./amm/request.js --walletN=2 --agentId=$AMMAGENT2
```

Output:

```
order {
  "ID": 2601,
  "AssetID": "0fLIp-xxRnQ8Nk-ruq8SBY8icaIvZMujnqCGU79fnM0",
  "MakeTx": "zkmqIcN2KNOS38zgAq5AxTfnMeod7OaZUcy_SMOGJqE",
  "ExpireDate": 1733297855923,
  "HolderAssetID": "AttsQGi4xgSOTeHM6CNgEVxlrdZi4Y86LQCF__p4HUM",
  "NoteID": "14ec8heZ5m3XR6j9ZBOIUT-3lhq6qgloaz9ObIG-_PI",
  "IssueDate": 1733297765923,
  "HolderAmount": "5",
  "Amount": "4",
  "Status": "Open",
  "Price": 1.25,
  "Issuer": "xhgS6MeQ4qhYqP21ptsCSHY3m9faNsPs0ewRKB9jvwo"
}
```

Set the `NoteID` to env variable.

```bash
export NOTEID=<NoteID>
```

#### 5. take this order by agent

Run

```bash
node ./basic/take.js --walletN=1 --agentId=$AGENT1 --noteId=$NOTEID
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
