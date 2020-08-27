module.exports = async () => {
  // Imports
  const Web3 = require("web3");
  const truffleContract = require("@truffle/contract");
  const tokenContract = truffleContract(
    require("../build/contracts/TestToken.json")
  );
  const erc20AppContract = truffleContract(
    require("../build/contracts/ERC20App.json")
  );

  const RECIPIENT = Buffer.from(
    "8eaf04151687736326c9fea17e25fc5287613693c912909cb226aa4794f26a48", "hex"
  );

  const TOKEN_AMOUNT = 100;

  // Set up provider and contracts
  let provider = new Web3.providers.HttpProvider("http://localhost:7545");
  const web3 = new Web3(provider);

  erc20AppContract.setProvider(web3.currentProvider);
  tokenContract.setProvider(web3.currentProvider);

  const accounts = await web3.eth.getAccounts();

  // 1. Send approval transaction
  try {
    const erc20AppAddress = await erc20AppContract.deployed().then(function(instance) {
      return instance.address;
    });

    console.log("1. Connected to TestToken contract, approving tokens to ERC20App contract...");
    const { logs } = await tokenContract.deployed().then(function (instance) {
      return instance.approve(erc20AppAddress, TOKEN_AMOUNT, {
        from: accounts[0],
        value: 0,
        gas: 300000 // 300,000 Gwei
      });
    });

    // Get event logs
    const event = logs.find(e => e.event === "Approval");

    // Parse event fields
    const approvalEvent = {
      owner: event.args.owner,
      spender: event.args.spender,
      value: Number(event.args.value)
    };

    console.log("ERC20 tokens successfully approved to ERC20App:\n", approvalEvent);
  } catch (error) {
    console.error({error})
  }

  // 2. Send ERC20 tokens to ERC20App
  try {
    const tokenContractAddress = await tokenContract.deployed().then(function(instance) {
      return instance.address;
    });

    const { logs } = await erc20AppContract.deployed().then(function (instance) {
      console.log("\n2. Connected to ERC20App contract, sending TestTokens...");
      return instance.sendERC20(RECIPIENT, tokenContractAddress, TOKEN_AMOUNT, {
        from: accounts[0],
        value: 0,
        gas: 300000 // 300,000 Gwei
      });
    });

    console.log("TestTokens succesfully sent to ERC20App:")

    // Get event logs
    const event = logs.find(e => e.event === "AppEvent");

    // Parse event fields
    const appEvent = {
      data: event.args._data,
    };

    console.log(appEvent);
  } catch (error) {
    console.error({ error });
  }

  return
};
