const { arJWK1, arJWK2, helloProcess, kittyProcess, getProcessResult, ao } = require('./config')
const aoconnect = require('@permaweb/aoconnect')
const { createDataItemSigner } = aoconnect

const testRun = async () => {
  for (let jwk of [arJWK1, arJWK2]) {
    const signer = createDataItemSigner(jwk)
  
    const claimHelloMessageId = await ao.message({
      process: helloProcess,
      signer,
      tags: [
        { name: 'Action', value: 'Claim' },
      ]
    })
    console.log('claimHelloMessageId', claimHelloMessageId)
  
    const claimHelloResult = await getProcessResult(claimHelloMessageId, helloProcess)
    console.log('claimHelloResult', JSON.stringify(claimHelloResult, null, 2))
  
    const claimKittyMessageId = await ao.message({
      process: kittyProcess,
      signer,
      tags: [
        { name: 'Action', value: 'Claim' },
      ]
    })
    console.log('claimKittyMessageId', claimKittyMessageId)
  
    const claimKittyResult = await getProcessResult(claimKittyMessageId, kittyProcess)
    console.log('claimKittyResult', JSON.stringify(claimKittyResult, null, 2))
  }
}

testRun()