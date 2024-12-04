const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, ao, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Orderbook, createOrderbookProcess } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})

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
	// set up amount by yourself
	const helloAmount = '304'
	const kittyAmount = '384'

  const address = await arweave.wallets.jwkToAddress(jwk)
  const signer = createDataItemSigner(jwk)
  const settleProcess = getSettleProcessId()
	const agent = new Orderbook(signer, agentId, settleProcess)

	console.log('address', address)
	console.log('agent', agentId)
  
    // withdraw 
    const depositHelloMessageId = await agent.withdraw(helloProcess, helloAmount)
    console.log('withdraw $Hello MsgId', depositHelloMessageId)
  
    const depositKittyMessageId = await agent.withdraw(kittyProcess, kittyAmount)
    console.log('withdraw $Kitty MsgId', depositKittyMessageId)
  
    // get balances of your orderbook agent process
    const balancesResult = await agent.balances()
    console.log('balancesResult', balancesResult)
}

testRun()