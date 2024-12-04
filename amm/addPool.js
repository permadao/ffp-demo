const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, ao, isProd, ammSlippageOfPercent } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { Amm } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})
// const process = require('process')

const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
    const [key, value] = arg.split('=');
    acc[key.replace(/^--/, '')] = value;
    return acc;
}, {});
const agentId = parsedArgs.agentId
const walletN = parsedArgs.walletN

const ammProcess = agentId

const jwk = [arJWK1, arJWK2][walletN - 1]
if (!jwk) {
    console.error('walletN is required')
    process.exit(1)
}

const testRun = async () => {
	// set up amount by yourself
	const helloAmount = '50'
  const kittyAmount = '50'

  const address = await arweave.wallets.jwkToAddress(jwk)
  const signer = createDataItemSigner(jwk)
	const agent = new Amm(signer, ammProcess)

	console.log('address', address)
	console.log('agent', ammProcess)

  const x = helloProcess < kittyProcess ? helloProcess : kittyProcess
  const y = helloProcess < kittyProcess ? kittyProcess : helloProcess
  const px = helloProcess < kittyProcess ? helloAmount : kittyAmount
  const py = helloProcess < kittyProcess ? kittyAmount : helloAmount
  
  const addPoolMessageId = await agent.addUniswapV2Pool(x, y, px, py, 30)
  const pools = await agent.getPools()
  console.log('pools', JSON.stringify(pools, null, 2))
}

testRun()