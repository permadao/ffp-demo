const { helloProcess, kittyProcess, ao } = require('./config')

const args = process.argv.slice(2);

const parsedArgs = args.reduce((acc, arg) => {
  const [key, value] = arg.split('=');
  acc[key.replace(/^--/, '')] = value;
  return acc;
}, {});

const testRun = async () => {
	const owner = parsedArgs.address
	console.log('address:', owner)

    msg = await ao.dryrun({
	  Id: '0000000000000000000000000000000000000000001',
      Owner: owner,
      process: helloProcess,
      tags: [
        { name: 'Action', value: 'Balance' },
      ]
    })
    console.log('$HELLO balance ', msg.Messages[0].Data)

    msg = await ao.dryrun({
	  Id: '0000000000000000000000000000000000000000001',
      Owner: owner,
      process: kittyProcess,
      tags: [
        { name: 'Action', value: 'Balance' },
      ]
    })
    console.log('$KITTY balance ', msg.Messages[0].Data)
}

testRun()