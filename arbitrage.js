const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, getTokenBalance, ao, isProd, ammSlippageOfPercent } = require('./config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { Amm, getSettleProcessId, Orderbook, createOrderbookProcess, arbitrage } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})


const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
    const [key, value] = arg.split('=');
    acc[key.replace(/^--/, '')] = value;
    return acc;
}, {});
const agentId = parsedArgs.agentId
const walletN = parsedArgs.walletN

const ammProcess = agentId

const jwk = [arJWK1, arJWK2][walletN - 1]
if (!jwk) {
    console.error('walletN is required')
    process.exit(1)
}

const testRun = async () => {
  const address = await arweave.wallets.jwkToAddress(jwk)
  const signer = createDataItemSigner(jwk)

  const settleProcess = getSettleProcessId(false)
  const ammAgent = new Amm(address, signer, ammProcess)
  const orderbookProcess = await createOrderbookProcess(address, signer, false)
  const orderbookAgent = new Orderbook(signer, orderbookProcess, settleProcess)

  await orderbookAgent.deposit(helloProcess, '100')
  await orderbookAgent.deposit(kittyProcess, '100')

  // make arbitrary orders
  const makeOrderMessageId = await orderbookAgent.makeOrder(helloProcess, kittyProcess, '10', '1')
  const myOrders = await orderbookAgent.getMyOrders(helloProcess, kittyProcess, 'Open', true, 1, 10)
  const orderbookOrder = myOrders[0]
  console.log('orderbookOrder', orderbookOrder)

  // get arbitrade order id from amm agent
  const arbitrageOrder = await ammAgent.getArbitrageOrder(myOrders[0])
  console.log('arbitrageOrder', arbitrageOrder)
  
  const helloBalanceBeforeArbitrage = await getTokenBalance(helloProcess, address)
  const kittyBalanceBeforeArbitrage = await getTokenBalance(kittyProcess, address)
  console.log('helloBalanceBeforeArbitrage', helloBalanceBeforeArbitrage)
  console.log('kittyBalanceBeforeArbitrage', kittyBalanceBeforeArbitrage)

  await arbitrage(signer, settleProcess, [orderbookOrder.NoteID, arbitrageOrder.NoteID])

  const helloBalanceAfterArbitrage = await getTokenBalance(helloProcess, address)
  const kittyBalanceAfterArbitrage = await getTokenBalance(kittyProcess, address)
  console.log('helloBalanceAfterArbitrage', helloBalanceAfterArbitrage)
  console.log('kittyBalanceAfterArbitrage', kittyBalanceAfterArbitrage)

}

testRun()