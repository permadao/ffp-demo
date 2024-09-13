const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, ao, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Orderbook, createOrderbookProcess } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})

const testRun = async () => {
	// set up the jwk(json) and agent id by yourself
	// const jwk = arJWK1
	// const agentId = 'TXVxifgmQxQGErobcUj7Yg2FJea5J6ey_WK2Bnctd1M'
	const jwk = arJWK2
	const agentId = 'Cns0yMx0Ey3Z6NvRX66U6LHXZCXLFbOGZA0xfUwG99A'

	// set up amount by yourself
	const helloAmount = '304'
	const kittyAmount = '384'

    const address = await arweave.wallets.jwkToAddress(jwk)
    const signer = createDataItemSigner(jwk)
    const settleProcess = getSettleProcessId(isProd)
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