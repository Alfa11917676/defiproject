// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const {ethers} = require("hardhat");

async function main() {
  NFT = await ethers.getContractFactory('governanceToken')
  TOKEN = await ethers.getContractFactory('MyToken')
  Distributor = await ethers.getContractFactory('distributorContract')
  rewardToken = await TOKEN.deploy()
  await rewardToken.deployTransaction.wait(2)
  console.log("Reward Token Deployed")
  await verifyContract(rewardToken.address,[])
  investorToken1 = await TOKEN.deploy()
  await investorToken1.deployTransaction.wait(2)
  console.log("Investor Token1 Deployed")
  await verifyContract(investorToken1.address)
  investorToken2 = await TOKEN.deploy()
  console.log("Investor Token2 Deployed")
  investorToken3 = await TOKEN.deploy()
  console.log("Investor Token3 Deployed")
  distributor = await Distributor.deploy(rewardToken.address)
  await distributor.deployTransaction.wait(2)
  console.log("Distributor Deployed")
  await verifyContract(distributor.address,[rewardToken.address])
  nft1 = await NFT.deploy('POOL1','POOL1')
  await nft1.deployTransaction.wait(2)
  console.log("NFT POOl1 Deployed")
  await verifyContract(nft1.address,["POOL1","POOL1"])
  nft2 = await NFT.deploy('POOL2','POOL2')
  console.log("NFT POOl2 Deployed")
  nft3 = await NFT.deploy('POOL3','POOL3')
  console.log("NFT POOl3 Deployed")
  await rewardToken.mint(distributor.address, ethers.utils.parseEther('100000'))
  await nft1.addDistributorAddress(distributor.address)
  await nft1.addAuthorisedMinter(distributor.address)
  await nft2.addDistributorAddress(distributor.address)
  await nft2.addAuthorisedMinter(distributor.address)
  await nft3.addDistributorAddress(distributor.address)
  await nft3.addAuthorisedMinter(distributor.address)
  await distributor.addCollectionPoolAddresses("0x14b330dF8F8a5Fc1389FBEF463eEFC59079d35f4","0x72C984294D692b88e574464B781E45C71a6e1132","0xc9CD422609da6705061D7c59182924361af79aa1")
  await distributor.addGovernanceTokenAddress(nft1.address,nft2.address,nft3.address)
  await distributor.addInsuranceFundAddress("0xb0e80DE54b19d5996Ed37fF8d2F41D7044422545")
  await distributor.addAuthorisedCaller(nft1.address)
  await distributor.addAuthorisedCaller(nft2.address)
  await distributor.addAuthorisedCaller(nft3.address)
  await distributor.whitelistTokenAddresses([investorToken1.address,investorToken2.address,investorToken3.address])
  await distributor.changeMinimumQuantum(60)
  await distributor.changeLockQuantumPerPool([0,350, 400])

  console.log('The rewardToken address is ', rewardToken.address)
  console.log('The investorToken1 address is ', investorToken1.address)
  console.log('The investorToken2 address is ', investorToken2.address)
  console.log('The investorToken3 address is ', investorToken3.address)
  console.log('The POOL1 NFT address is ', nft1.address)
  console.log('The POOL2 NFT address is ', nft2.address)
  console.log('The POOL3 NFT address is ', nft3.address)
  console.log('The distributor contract address is', distributor.address)
}
async function verifyContract(contractAddress,args) {
  console.log('Verify')
  try {
    await hre.run("verify:verify", {
      address: contractAddress,
      constructorArguments: args,
    });
    return 0;
  }catch (e) {
    console.log('The error is ', e)
    return 0;
  }
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
