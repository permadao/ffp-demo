const { arJWK1, helloProcess, kittyProcess, isProd } = require('../config')
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

const testRun = async () => {
  const settleProcess = getSettleProcessId(isProd)
  const signer = createDataItemSigner(arJWK1)
  const agent = new Orderbook(signer, agentId, settleProcess)

  // get opened order
  const openOrders = await agent.getMyOrders(helloProcess, kittyProcess, 'Open', false)
  console.log('openOrders', openOrders)
}

testRun()