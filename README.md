A demo to use javascript ffp(FusionFi Protocol) sdk

## Install

```bash
npm install
# or
yarn add
```

## Run orderbook case

### 1. Set up config

Generate some new wallets for test.

```bash
make wallets
node ./generate.js
```

Set up `WALLET1` & `WALLET2` environment variables in `.env.local` file.

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

### 3. Create your orderbook agent

```bash
node ./orderbook/create.js
```

Output:

```
wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM create orderbook agent: <YourOrderBookAgent1>
ORHaLUrAiknTAq2Wszoyl6buJrd3MqDKLTF_2CggLtw create orderbook agent: <YourOrderBookAgent2>
```

Set up `WALLET1` & `WALLET2` environment variables in `.env.local` file.

```bash
export $(cat .env.local | xargs)
```

### 4. Deposit token to your orderbook agent

Deposit into your orderbook

```bash
node ./orderbook/deposit.js --walletN=1 --agentId=$AGENT1
```

If you will check balances in your agent:

```bash
node ./balance.js --address=$AGENT1
```

Do the same for the second agent.

```bash
node ./orderbook/deposit.js --walletN=2 --agentId=$AGENT2
node ./balance.js --address=$AGENT2
```

### 5. Make order

We use the first one agent to create a new order.

Run make.js

```bash
node ./orderbook/make.js --agentId=$AGENT1
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
node ./orderbook/query.js --agentId=$AGENT1
```

Set the `NoteID` to env variable.

```bash
export NOTEID=<NoteID>
```

### 6. Take order

Run

```bash
node ./orderbook/take.js --agentId=$AGENT2 --noteId=$NOTEID
```

After transaction done, the balances of both agents have been updated, and the transaction is complete.

```bash
node ./balance.js --address=$AGENT1
node ./balance.js --address=$AGENT2
```