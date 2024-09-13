const { arJWK2, helloProcess, kittyProcess, getProcessResult, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Orderbook } = aoffp
const { createDataItemSigner } = aoconnect

const testRun = async () => {
  const agentId = 'Cns0yMx0Ey3Z6NvRX66U6LHXZCXLFbOGZA0xfUwG99A'
  const settleProcess = getSettleProcessId(isProd)

  // take order by signer
  const signer = createDataItemSigner(arJWK2)
  const agent = new Orderbook(signer, agentId, settleProcess)

  const takeOrderMessageId = await agent.takeOrder(['pKK3aXTn-7oR50w33y_bwIwt3x4eRPxWjYeEzWOq2Mg'])
  console.log('take order MsgId', takeOrderMessageId)
}

testRun()