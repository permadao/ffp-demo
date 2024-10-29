const { arJWK1, arJWK2 } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { createAmmProcess } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})
const fs = require('node:fs')

const testRun = async () => {
  let i = 1
  for (let jwk of [arJWK1, arJWK2]) {
    const address = await arweave.wallets.jwkToAddress(jwk)
    const signer = createDataItemSigner(jwk)
    agentId = await createAmmProcess(signer)
    console.log(address, 'create amm agent:', agentId)

	fs.appendFileSync(".env.local", `AMMAGENT${i}=${agentId}\n`);
	i++;
  }
  
}

testRun()