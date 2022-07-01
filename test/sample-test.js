const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Greeter", function () {
  it("Should return the new greeting once it's changed", async function () {
    const distributorContract = await ethers.getContractFactory("distributorContract");
    const distributor = await distributorContract.deploy();
    await distributor.deployed();
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
    await distributor.deposit(1,"0x8626f6940E2eb28930eFb4CeF49B2d1F2C9C1199",12)
  });
});
