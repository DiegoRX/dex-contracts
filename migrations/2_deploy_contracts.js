
const CoffeeBeans = artifacts.require('CoffeeBeans.sol') 
const MasterChef = artifacts.require('MasterChef.sol'); 

module.exports = async function(deployer, _network, addresses) {
  const [admin, _] = addresses;


  const WMATIC = {address: '0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270'}


  await deployer.deploy(CoffeeBeans);
  const coffeeBeans = await CoffeeBeans.deployed();

  await deployer.deploy(
    MasterChef,
    coffeeBeans.address,
    admin,
    web3.utils.toWei('100'),
    1,
    1
  );
  const masterChef = await MasterChef.deployed();
  await coffeeBeans.transferOwnership(masterChef.address);


};
