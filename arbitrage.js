const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, getTokenBalance, ao, isProd, ammSlippageOfPercent } = require('./config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { Amm, Agent, getSettleProcessId, Orderbook, createOrderbookProcess, arbitrage } = aoffp
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


const testRun = async () => {
  const settleProcess = getSettleProcessId(false)

  const signer1 = createDataItemSigner(arJWK1)
  const agent = new Agent(signer1, agentId, settleProcess)

  const address = await arweave.wallets.jwkToAddress(arJWK2)
  const signer2 = createDataItemSigner(arJWK2)
  
  const ammAgent = new Amm(address, signer2, ammProcess)
  const orderbookAgent = new Orderbook(signer2, orderbookAgentId, settleProcess)

  await orderbookAgent.deposit(helloProcess, '100')
  await orderbookAgent.deposit(kittyProcess, '100')

  // make an ORDERBOOKAGENT2 10 hello -> 1 kitty order
  const makeOrderMessageId = await orderbookAgent.makeOrder(helloProcess, kittyProcess, '10', '1')
  const myOrders = await orderbookAgent.getMyOrders(helloProcess, kittyProcess, 'Open', true, 1, 10)
  const orderbookOrder = myOrders[0]
  console.log('orderbookOrder', orderbookOrder)

  // get arbitrade order id from amm agent
  const arbitrageOrder = await ammAgent.makeOrder(orderbookOrder.AssetID, orderbookOrder.Amount, ammSlippageOfPercent)
  console.log('arbitrageOrder', arbitrageOrder)

  if (+arbitrageOrder.Amount <= +orderbookOrder.HolderAmount) {
    console.log('this order can not be arbitraged')
    return
  }


  const balanceBefore = await agent.balances()
  console.log('agent balanceBefore', balanceBefore)
  const takeOrderMessageId = await agent.takeOrder([orderbookOrder.NoteID, arbitrageOrder.NoteID])
  console.log('takeOrderMessageId', takeOrderMessageId)

  await new Promise((resolve) => {
    setTimeout(resolve, 2000)
  })

  const balanceAfter = await agent.balances()
  console.log('agent balanceAfter', balanceAfter)
}

testRun()