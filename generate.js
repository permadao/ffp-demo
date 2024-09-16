const fs = require('node:fs');
const Arweave = require('arweave')

async function main() {
  const arweave = Arweave.init({});

  const wallet1 = await arweave.wallets.generate();
  const wallet2 = await arweave.wallets.generate();

  fs.writeFileSync("./wallets/wallet1.json", JSON.stringify(wallet1));
  fs.writeFileSync("./wallets/wallet2.json", JSON.stringify(wallet2));

  const address1 = await arweave.wallets.jwkToAddress(wallet1);
  const address2 = await arweave.wallets.jwkToAddress(wallet2);

  console.log('wallet1', address1, '\nwallet2', address2);
  const envText = `WALLET1=${address1}\nWALLET2=${address2}\n`;
  fs.writeFileSync(".env.local", envText);
}

main()
