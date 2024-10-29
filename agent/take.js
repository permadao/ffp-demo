const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Agent } = aoffp
const { createDataItemSigner } = aoconnect

const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace(/^--/, '')] = value;
  return acc;
}, {});
const agentId = parsedArgs.agentId
const noteId = parsedArgs.noteId
const walletN = parsedArgs.walletN

const jwk = [arJWK1, arJWK2][walletN - 1]
if (!jwk) {
    console.error('walletN is required')
    process.exit(1)
}

const testRun = async () => {
  const settleProcess = getSettleProcessId(isProd)

  // take order by signer
  const signer = createDataItemSigner(jwk)
  const agent = new Agent(signer, agentId, settleProcess)

  const takeOrderMessageId = await agent.takeOrder([noteId])
  console.log('take order MsgId', takeOrderMessageId)
}

testRun()