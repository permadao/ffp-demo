A demo to use javascript ffp(FusionFi Protocol) sdk

## Install

```bash
npm install aoffp bignumber.js axios
# or
yarn add aoffp bignumber.js axios
```

## Run orderbook case

If you're not using your own keys, the repos have already provided two test wallets, agents, and test tokens for you. Please start from step 5.

### 1. Set up config

Put your ar keyfile object to `./wallets/wallet1.json` and `./wallets/wallet2.json`.

Must named `wallet1.json` and `wallet2.json`.

### 2. Get token airdrop

We set $HELLO & $KITTY token for test, you can get those tokens by `airdrop.js`.

```bash
node ./airdrop.js
```

When this flow is done, you can check the balance:

```bash
node ./balance.js --address='wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM'
```

Output:

```
address: wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM
$HELLO balance  100000000000000
$KITTY balance  100000000000000
```

### 3. Create your orderbook agent

```bash
node ./orderbook/create.js
```

Output:

```
wBn7-31aDtChhLfUk_eXNG9Nbafa_ghT29XRxk7osiM create orderbook agent: 8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw
ORHaLUrAiknTAq2Wszoyl6buJrd3MqDKLTF_2CggLtw create orderbook agent: Cns0yMx0Ey3Z6NvRX66U6LHXZCXLFbOGZA0xfUwG99A
```

Record those orderbook agents id. It's will be used next step.

### 4. Deposit token to your orderbook agent

Edit ./orderbook/deposit.js and set your agent id.

```javascript
...
	// set the jwk(json) and agent id by yourself
	const jwk = arJWK1
	// We create two orderbook agents for the test, this is the first one 
	const agentId = '8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw'
...
```

Run

```bash
node ./orderbook/create.js
```

If you will check balances in your agent:

```bash
node ./balance.js --address='8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw'
```

Edit `deposit.js` again, set your second agent id. Run and check agent balance again. Then those two agents had $HELLO and $KITTY tokens.

### 5. Make order

We use the first one agent to create a new order. So you need to set first agent id in `make.js`.

Edit ./orderbook/make.js

```javascript
...
const agentId = '8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw'
...
```

Run make.js

```bash
node ./orderbook/make.js
```

Output:

```
make order MsgId iZzNQW0nem81JlgNk3fm1TXmwtK2mq2lwBoDvALeguM
openOrders [
  {
    ID: 1,
    HolderAssetID: '4557tfvtAlS8WS0-KF0sGdfgy6An2dcVXQUGocrKV7U',
    HolderAmount: '3',
    NoteID: 'pKK3aXTn-7oR50w33y_bwIwt3x4eRPxWjYeEzWOq2Mg',
    Issuer: '8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw',
    Type: 'Orderbook',
    AssetID: '-v4cUCUcRiJH67jPMUt-Uhn-K4PHxrkoySM2uqAjAF0',
    IssueDate: 1726236373254,
    Status: 'Open',
    Amount: '1'
  }
]
```

Record the NoteID, if taker want to fill this order, use NoteID for settlement.

### 6. Take order

Edit ./orderbook/take.js, set agent id and note id.

```javascript
// set your agent id here
const agentId = 'Cns0yMx0Ey3Z6NvRX66U6LHXZCXLFbOGZA0xfUwG99A'
const settleProcess = getSettleProcessId(isProd)

...

// set your note id here
const takeOrderMessageId = await agent.takeOrder(['MfaTTMa0q50Y4uQiB8TWndpvqM2zOfBarNMMHHTZehI'])
console.log('take order MsgId', takeOrderMessageId)
```

Run

```bash
node ./orderbook/take.js
```

After transaction done, the balances of both agents have been updated, and the transaction is complete.

```bash
node ./balance.js --address='8GIoDaxheWB2HSvdWehQHrIYilzIty5_8NZt4XHojpw'
node ./balance.js --address='Cns0yMx0Ey3Z6NvRX66U6LHXZCXLFbOGZA0xfUwG99A'
```