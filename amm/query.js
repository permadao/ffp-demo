const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, ao, isProd, ammSlippageOfPercent, BN } = require('../config')
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

  const info = await agent.info()
  console.log('pool info', JSON.stringify(info, null, 2))
  
  if (info.PX && info.PY) {
    const rate = new BN(info.PY).dividedBy(new BN(10).pow(info.DecimalY)).dividedBy(new BN(info.PX).dividedBy(new BN(10).pow(info.DecimalX))).toString()
    console.log(`1 $${info.SymbolX} = ${rate} $${info.SymbolY}`)  
  } else {
    console.log('liquidity not added')
  }
}

testRun()