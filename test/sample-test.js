const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const distributorContract = await ethers.getContractFactory("distributorContract");
    const distributor = await distributorContract.deploy('0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199');
    await distributor.deployed();
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(3,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(2,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(2,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(3,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    let data1 = await distributor.nftIndexPerPool(0)
    let data2 = await distributor.nftIndexPerPool(1)
    let data3 = await distributor.nftIndexPerPool(2)
    let data4 = await distributor.nftIndexPerPool(3)
    console.log(data1)
    console.log(data2)
    console.log(data3)
    console.log(data4)
  });
});
