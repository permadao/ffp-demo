const fs = require('node:fs')
const { arJWK1, arJWK2, isProd } = require('../config')
const aoffp = require('aoffp')
const Arweave = require('arweave')
const aoconnect = require('@permaweb/aoconnect')
const { createAgentProcess } = aoffp
const { createDataItemSigner } = aoconnect
const arweave = Arweave.init({})

const testRun = async () => {
  let i = 1
  for (let jwk of [arJWK1, arJWK2]) {
    const address = await arweave.wallets.jwkToAddress(jwk)
    const signer = createDataItemSigner(jwk)

    agentId = await createAgentProcess(signer, isProd)
    console.log(address, 'create agent:', agentId)

    fs.appendFileSync(".env.local", `AGENT${i}=${agentId}\n`);
    i++;
  }
}

testRun()