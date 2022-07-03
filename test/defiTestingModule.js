const { expect } = require("chai");
const { ethers } = require("hardhat");
const Web3 = require ("web3")
const {fromWei} = Web3.utils

describe("Test-suite for Distributor Contract", async function () {
  let pool1, pool2, pool3, nft1, nft2, nft3, rewardToken, investorToken1, investorToken2, investorToken3, distributor, insuranceFund, alice, bob, charlie, initialTime, oneDay
  before("Setting Up The Test Suite",async()=>{
        [alice, bob, charlie, pool1, pool2, pool3, insuranceFund] = await ethers.getSigners()
        NFT = await ethers.getContractFactory('governanceToken')
        TOKEN = await ethers.getContractFactory('MyToken')
        Distributor = await ethers.getContractFactory('distributorContract')
        rewardToken = await TOKEN.deploy()
        investorToken1 = await TOKEN.deploy()
        investorToken2 = await TOKEN.deploy()
        investorToken3 = await TOKEN.deploy()
        distributor = await Distributor.deploy(rewardToken.address)
        nft1 = await NFT.deploy('POOL1','POOL1')
        nft2 = await NFT.deploy('POOL2','POOL2')
        nft3 = await NFT.deploy('POOL3','POOL3')
        await investorToken3.connect(charlie).approve(distributor.address,ethers.utils.parseEther('100000'));
        await investorToken2.connect(bob).approve(distributor.address,ethers.utils.parseEther('100000'));
        await investorToken1.connect(alice).approve(distributor.address,ethers.utils.parseEther('100000'));
        await investorToken1.connect(pool1).approve(distributor.address,ethers.utils.parseEther('100000'));
        await rewardToken.mint(distributor.address, ethers.utils.parseEther('100000'))
        await investorToken1.mint(alice.address, ethers.utils.parseEther('100000'))
        await investorToken2.mint(bob.address, ethers.utils.parseEther('100000'))
        await investorToken3.mint(charlie.address, ethers.utils.parseEther('100000'))
        await nft1.addDistributorAddress(distributor.address)
        await nft1.addAuthorisedMinter(distributor.address)
        await nft2.addDistributorAddress(distributor.address)
        await nft2.addAuthorisedMinter(distributor.address)
        await nft3.addDistributorAddress(distributor.address)
        await nft3.addAuthorisedMinter(distributor.address)
        await distributor.addCollectionPoolAddresses(pool1.address,pool2.address,pool3.address)
        console.log('The token allowance is: ',await investorToken1.allowance(pool1.address, distributor.address))
        await distributor.addGovernanceTokenAddress(nft1.address,nft2.address,nft3.address)
        await distributor.addInsuranceFundAddress(insuranceFund.address)
        await distributor.addAuthorisedCaller(nft1.address)
        await distributor.addAuthorisedCaller(nft2.address)
        await distributor.addAuthorisedCaller(nft3.address)
        await distributor.whitelistTokenAddresses([investorToken1.address,investorToken2.address,investorToken3.address])
        const block = await ethers.getDefaultProvider().getBlock('latest')
        initialTime = block.timestamp
        oneDay = 86400
        console.log('All set for testing')
  });
  it("Test1: Staking Testing", async function () {
          await distributor.deposit(1,investorToken1.address,100)
          let details = await distributor.viewNftDetails(1,1)
          expect(fromWei(details[3].toString(),"ether")).to.eq("75")
          expect(fromWei(details[2].toString(),"wei")).to.eq('20')
          expect(details[7]).to.eq(investorToken1.address)
          expect(await nft1.balanceOf(alice.address)).to.eq(1)
  });
  it ("Test2: Claim Testing", async()=> {
      await network.provider.send("evm_setNextBlockTimestamp", [initialTime+1 * oneDay+ 3600])
      await network.provider.send("evm_mine")
      let amount = await distributor.getRewardDetails(1,1);
      expect(fromWei(amount.toString(),"ether")).to.eq("1.875")
      await distributor.claimFunds([1],[1])
      expect(await rewardToken.balanceOf(alice.address)).to.equal(ethers.utils.parseEther('1.875'))
  })
  it ("Test3: Transfer The NFT", async()=> {
        await nft1.setApprovalForAll(nft1.address,true)
        await nft1.transferFrom(alice.address,bob.address,1)
        await network.provider.send("evm_setNextBlockTimestamp", [initialTime+2 * oneDay+ 2 * 3600])
        await network.provider.send("evm_mine")
        let amount = await distributor.getRewardDetails(1,1);
        expect(fromWei(amount.toString(),"ether")).to.eq("1.875")
        await expect (distributor.connect(alice).claimFunds([1],[1])).to.be.revertedWith('Error: Caller Not Owner')
        await expect (distributor.connect(charlie).claimFunds([1],[1])).to.be.revertedWith('Error: Caller Not Owner')
        await expect (distributor.connect(charlie).claimFunds([2],[1])).to.be.reverted
        await distributor.connect(bob).claimFunds([1],[1])
        expect(await rewardToken.balanceOf(bob.address)).to.equal(ethers.utils.parseEther('1.875'))
    })
  it ("Test4: Unstake The Tokens", async () => {
      await network.provider.send("evm_setNextBlockTimestamp", [initialTime+10 * oneDay+ 3 * 3600])
      await network.provider.send("evm_mine")
      await distributor.connect(bob).unstakeTokens([1],[1])
      expect (await nft1.balanceOf(bob.address)).to.eq('0')
  })

});
