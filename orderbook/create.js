const fs = require('node:fs')
const { arJWK1, arJWK2, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { createOrderbookProcess } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})

const testRun = async () => {
  let i = 1
  for (let jwk of [arJWK1, arJWK2]) {
    const address = await arweave.wallets.jwkToAddress(jwk)
    const signer = createDataItemSigner(jwk)

    agentId = await createOrderbookProcess(address, signer, isProd)
    console.log(address, 'create orderbook agent:', agentId)

	fs.appendFileSync(".env.local", `AGENT${i}=${agentId}\n`);
	i++;
  }
}

testRun()