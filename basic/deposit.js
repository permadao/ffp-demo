const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, ao, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { getSettleProcessId, Orderbook, createOrderbookProcess } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})
// const process = require('process')

const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
    const [key, value] = arg.split('=');
    acc[key.replace(/^--/, '')] = value;
    return acc;
}, {});
const walletN = parsedArgs.walletN
const agentId = parsedArgs.agentId

const testRun = async () => {
	// set up the jwk(json) and agent id by yourself
	const jwk = [arJWK1, arJWK2][walletN - 1]
    if (!jwk) {
        console.error('walletN is required')
        process.exit(1)
    }

	// set up amount by yourself
	const helloAmount = '100'
	const kittyAmount = '100'

    const address = await arweave.wallets.jwkToAddress(jwk)
    const signer = createDataItemSigner(jwk)
    const settleProcess = getSettleProcessId()
	const agent = new Orderbook(signer, agentId, settleProcess)

	console.log('address', address)
	console.log('agent', agentId)
  
    // deposit
    const depositHelloMessageId = await agent.deposit(helloProcess, helloAmount)
    console.log('deposit $Hello MsgId', depositHelloMessageId)
  
    const depositKittyMessageId = await agent.deposit(kittyProcess, kittyAmount)
    console.log('deposit $Kitty MsgId', depositKittyMessageId)

}

testRun()