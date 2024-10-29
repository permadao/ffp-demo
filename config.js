const axios = require('axios')
// Create fetch funciton for ao spwan
global.fetch = async (url, options = {}) => {
  const { method = 'GET', headers, body } = options;

  try {
    const response = await axios({
      url,
      method,
      headers,
      data: body,
      validateStatus: () => true, // allow all status code for ao spwan
    });

    return {
      ok: response.status >= 200 && response.status < 300,
      status: response.status,
      statusText: response.statusText,
      json: async () => response.data,
      text: async () => JSON.stringify(response.data),
      headers: {
        get: (name) => response.headers[name.toLowerCase()],
      },
    };
  } catch (error) {
    throw new Error(`Fetch error: ${error.message}`);
  }
};

const fs = require('fs')
const BN = require('bignumber.js')
const path = require('path')
const aoconnect = require('@permaweb/aoconnect')
const { connect } = aoconnect

BN.config({
  EXPONENTIAL_AT: 1000
})

const defaultAOConfig = {
  CU_URL: 'https://cu.ao-testnet.xyz',
  MU_URL: 'https://mu.ao-testnet.xyz',
  GATEWAY_URL: 'https://g8way.io:443'
}

const isProd = false

const arJWK1 = JSON.parse(fs.readFileSync(path.resolve(__dirname, './wallets/wallet1.json')))
const arJWK2 = JSON.parse(fs.readFileSync(path.resolve(__dirname, './wallets/wallet2.json')))

// test tokens
const helloProcess = '-v4cUCUcRiJH67jPMUt-Uhn-K4PHxrkoySM2uqAjAF0'
const kittyProcess = '4557tfvtAlS8WS0-KF0sGdfgy6An2dcVXQUGocrKV7U'
const ao = connect(defaultAOConfig)

const getProcessResult = async (message, process) => {
  const { Messages, Error, Output, Spawns } = await ao.result({
    message: message,
    process: process
  })
  return { message: Messages, output: Output, spawns: Spawns, err: Error }
}

const ammSlippageOfPercent = 0.5

const getTokenBalance = async (process, address) => {
  const res = await ao.dryrun({
	  Id: '0000000000000000000000000000000000000000001',
    Owner: address,
    process: process,
    tags: [
      { name: 'Action', value: 'Balance' },
    ]
  })
  return res.Messages[0].Data
}

module.exports = {
  ao,
  BN,
  isProd,
  defaultAOConfig,
  arJWK1,
  arJWK2,
  helloProcess,
  kittyProcess,
  getProcessResult,
  getTokenBalance,
  ammSlippageOfPercent
}