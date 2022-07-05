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
  Pool = await ethers.getContractFactory("poolContract")
  rewardToken1 = await TOKEN.deploy('RewardToken1','RTK1')
  rewardToken2 = await TOKEN.deploy('RewardToken2','RTK2')
  rewardToken3 = await TOKEN.deploy('RewardToken3','RTK3')
  await rewardToken1.deployTransaction.wait(2)
  console.log("Reward Token Deployed")
  await verifyContract(rewardToken1.address,['RewardToken1','RTK1'])
  investorToken1 = await TOKEN.deploy('InvestorToken1','ITK1')
  await investorToken1.deployTransaction.wait(2)
  console.log("Investor Token1 Deployed")
  await verifyContract(investorToken1.address)
  investorToken2 = await TOKEN.deploy('InvestorToken2','ITK2')
  console.log("Investor Token2 Deployed")
  investorToken3 = await TOKEN.deploy('InvestorToken3','ITK3')
  console.log("Investor Token3 Deployed")
  distributor = await Distributor.deploy()
  await distributor.deployTransaction.wait(2)
  console.log("Distributor Deployed")
  await verifyContract(distributor.address,[])
  nft1 = await NFT.deploy('POOL1','POOL1')
  await nft1.deployTransaction.wait(2)
  console.log("NFT POOl1 Deployed")
  await verifyContract(nft1.address,["POOL1","POOL1"])
  nft2 = await NFT.deploy('POOL2','POOL2')
  console.log("NFT POOl2 Deployed")
  nft3 = await NFT.deploy('POOL3','POOL3')
  console.log("NFT POOl3 Deployed")
  collectionPool1 = await Pool.deploy()
  console.log("CollectionPool1 deployed")
  await collectionPool1.deployTransaction.wait(2)
  await verifyContract(collectionPool1.address,[])
  collectionPool2 = await Pool.deploy()
  console.log("CollectionPool2 deployed")
  collectionPool3 = await Pool.deploy()
  console.log("CollectionPool3 deployed")
  await rewardToken1.mint(collectionPool1.address, ethers.utils.parseEther('100000'))
  await rewardToken2.mint(collectionPool2.address, ethers.utils.parseEther('100000'))
  await rewardToken3.mint(collectionPool3.address, ethers.utils.parseEther('100000'))
  await collectionPool1.addRewardTokenAddress(rewardToken1.address)
  await collectionPool2.addRewardTokenAddress(rewardToken2.address)
  await collectionPool3.addRewardTokenAddress(rewardToken3.address)
  await collectionPool1.addAuthorisedCaller(distributor.address)
  await collectionPool2.addAuthorisedCaller(distributor.address)
  await collectionPool3.addAuthorisedCaller(distributor.address)
  await nft1.addDistributorAddress(distributor.address)
  await nft1.addAuthorisedMinter(distributor.address)
  await nft2.addDistributorAddress(distributor.address)
  await nft2.addAuthorisedMinter(distributor.address)
  await nft3.addDistributorAddress(distributor.address)
  await nft3.addAuthorisedMinter(distributor.address)
  await distributor.addCollectionPoolAddresses(collectionPool1.address,collectionPool2.address,collectionPool3.address)
  await distributor.addGovernanceTokenAddress(nft1.address,nft2.address,nft3.address)
  await distributor.addInsuranceFundAddress("0xb0e80DE54b19d5996Ed37fF8d2F41D7044422545")
  await distributor.addAuthorisedCaller(nft1.address)
  await distributor.addAuthorisedCaller(nft2.address)
  await distributor.addAuthorisedCaller(nft3.address)
  await distributor.whitelistTokenAddresses([investorToken1.address,investorToken2.address,investorToken3.address])
  await distributor.changeMinimumQuantum(60)
  await distributor.changeLockQuantumPerPool([0,350, 400])

  console.log('The rewardToken1 address is ', rewardToken1.address)
  console.log('The rewardToken2 address is ', rewardToken2.address)
  console.log('The rewardToken3 address is ', rewardToken3.address)
  console.log('The investorToken1 address is ', investorToken1.address)
  console.log('The investorToken2 address is ', investorToken2.address)
  console.log('The investorToken3 address is ', investorToken3.address)
  console.log('The POOL1 NFT address is ', nft1.address)
  console.log('The POOL2 NFT address is ', nft2.address)
  console.log('The POOL3 NFT address is ', nft3.address)
  console.log('The CollectionPool1 address is ', collectionPool1.address)
  console.log('The CollectionPool2 address is ', collectionPool2.address)
  console.log('The CollectionPool3 address is ', collectionPool3.address)
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
    console.log('Already Verified')
    return 0;
  }
}
// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
