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
  const address = await arweave.wallets.jwkToAddress(jwk)
  const signer = createDataItemSigner(jwk)
	const agent = new Amm(address, signer, ammProcess)

	console.log('address', address)
	console.log('agent', ammProcess)

  const balanceResult = await agent.balance()
  console.log('balanceResult', balanceResult)
  
  const removeLiquidityMessageId = await agent.removeLiquidity(balanceResult.Balance, ammSlippageOfPercent)
  const removeLiquidityResult = await getProcessResult(removeLiquidityMessageId, ammProcess)
  console.log('removeLiquidityResult', JSON.stringify(removeLiquidityResult, null, 2))
}

testRun()