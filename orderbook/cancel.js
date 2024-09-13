const { arJWK1, helloProcess, kittyProcess, isProd } = require('../config')
const aoffp = require('aoffp')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Orderbook } = aoffp
const { createDataItemSigner } = aoconnect

const testRun = async () => {
  const agentId = 'TXVxifgmQxQGErobcUj7Yg2FJea5J6ey_WK2Bnctd1M'

  const settleProcess = getSettleProcessId(isProd)
  const signer = createDataItemSigner(arJWK1)
  const agent = new Orderbook(signer, agentId, settleProcess)

  await agent.cancelOrder('cBl0bL8jMKy-pfuv_YWf_---V-RjvlMJBYCq93ZfJ_g')

  // get opened order
  const openOrders = await agent.getMyOrders(helloProcess, kittyProcess, 'Open', false)
  console.log('openOrders', openOrders)
}

testRun()