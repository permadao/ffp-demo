const { arJWK2, helloProcess, kittyProcess, getProcessResult, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
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
const noteId = parsedArgs.noteId

const testRun = async () => {
  const settleProcess = getSettleProcessId(isProd)

  // take order by signer
  const signer = createDataItemSigner(arJWK2)
  const agent = new Orderbook(signer, agentId, settleProcess)

  const takeOrderMessageId = await agent.takeOrder([noteId])
  console.log('take order MsgId', takeOrderMessageId)
}

testRun()