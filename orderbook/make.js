const { arJWK1, arJWK2, helloProcess, kittyProcess, isProd } = require('../config')
const aoffp = require('aoffp')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Orderbook } = aoffp
const { createDataItemSigner } = aoconnect

const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace(/^--/, '')] = value;
  return acc;
}, {});
const agentId = parsedArgs.agentId
const walletN = parsedArgs.walletN

const jwk = [arJWK1, arJWK2][walletN - 1]
if (!jwk) {
    console.error('walletN is required')
    process.exit(1)
}


const testRun = async () => {
  const settleProcess = getSettleProcessId()
  const signerA = createDataItemSigner(jwk)
  const agent = new Orderbook(signerA, agentId, settleProcess)

  // signer make order
  const order = await agent.makeOrder(helloProcess, kittyProcess, '1', '3')
  console.log('make order', order)

  // get opened order
  const openOrders = await agent.getMyOrders(helloProcess, kittyProcess, 'Open', false)
  console.log('openOrders', openOrders)
}

testRun()