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
	const helloAmount = '100'

  const address = await arweave.wallets.jwkToAddress(jwk)
  const signer = createDataItemSigner(jwk)
	const agent = new Amm(address, signer, ammProcess)

	console.log('address', address)
	console.log('agent', ammProcess)
  
  const minLiquidity = await agent.getMinLiquidityByX(helloAmount, ammSlippageOfPercent)
  const addLiquidityMessageId = await agent.addLiquidity(minLiquidity)
  const addLiquidityResult = await getProcessResult(addLiquidityMessageId, ammProcess)
  console.log('addLiquidityResult', JSON.stringify(addLiquidityResult, null, 2))
}

testRun()