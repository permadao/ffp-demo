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
  const signerA = createDataItemSigner(arJWK1)
  const agent = new Orderbook(signerA, agentId, settleProcess)

  // signer make order
  const makeOrderMessageId = await agent.makeOrder(helloProcess, kittyProcess, '1', '3')
  console.log('make order MsgId', makeOrderMessageId)

  // get opened order
  const openOrders = await agent.getMyOrders(helloProcess, kittyProcess, 'Open', false)
  console.log('openOrders', openOrders)
}

testRun()