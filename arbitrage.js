const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, getTokenBalance, ao, isProd, ammSlippageOfPercent } = require('./config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { Amm, Basic, getSettleProcessId, Orderbook, createOrderbookProcess, arbitrage } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})


const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
    const [key, value] = arg.split('=');
    acc[key.replace(/^--/, '')] = value;
    return acc;
}, {});
const agentId = parsedArgs.agentId
const orderbookAgentId = parsedArgs.orderbookAgentId
const ammAgentId = parsedArgs.ammAgentId

const ammProcess = ammAgentId

const balances = async (owner) => {
  let msg = await ao.dryrun({
	  Id: '0000000000000000000000000000000000000000001',
      Owner: owner,
      process: helloProcess,
      tags: [
        { name: 'Action', value: 'Balance' },
      ]
    })
    console.log('$HELLO balance ', msg.Messages[0].Data)

    msg = await ao.dryrun({
	  Id: '0000000000000000000000000000000000000000001',
      Owner: owner,
      process: kittyProcess,
      tags: [
        { name: 'Action', value: 'Balance' },
      ]
    })
    console.log('$KITTY balance ', msg.Messages[0].Data)
}


const testRun = async () => {
  const settleProcess = getSettleProcessId()

  const signer1 = createDataItemSigner(arJWK1)
  const agent = new Basic(signer1, agentId, settleProcess)

  const address = await arweave.wallets.jwkToAddress(arJWK2)
  const signer2 = createDataItemSigner(arJWK2)
  
  const orderbookAgent = new Orderbook(signer2, orderbookAgentId, settleProcess)

  await orderbookAgent.deposit(helloProcess, '100')
  await orderbookAgent.deposit(kittyProcess, '100')

  // make an ORDERBOOKAGENT2 10 hello -> 1 kitty order
  const orderbookOrder = await orderbookAgent.makeOrder(helloProcess, kittyProcess, '10', '1')
  console.log('orderbookOrder', orderbookOrder)

  // get arbitrade order id from amm agent
  const arbitrageOrder = await aoffp.ammRequest(signer1, ammProcess, orderbookOrder.AssetID, orderbookOrder.Amount, orderbookOrder.HolderAssetID)
  console.log('arbitrageOrder', arbitrageOrder)

  if (+arbitrageOrder.Amount <= +orderbookOrder.HolderAmount) {
    console.log('this order can not be arbitraged')
    return
  }


  console.log('agent balanceBefore')
  await balances(agent.agentId)
  const takeOrderMessageId = await agent.takeOrder([orderbookOrder.NoteID, arbitrageOrder.NoteID])
  console.log('takeOrderMessageId', takeOrderMessageId)

  await new Promise((resolve) => {
    setTimeout(resolve, 10000)
  })

  console.log('agent balanceAfter')
  await balances(agent.agentId)
}

testRun()