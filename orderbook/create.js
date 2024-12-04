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

    const orderbookAgent = await createOrderbookProcess(signer)
    const agentId = orderbookAgent.agentId
    console.log(address, 'create orderbook agent:', agentId)

	fs.appendFileSync(".env.local", `ORDERBOOKAGENT${i}=${agentId}\n`);
	i++;
  }
}

testRun()