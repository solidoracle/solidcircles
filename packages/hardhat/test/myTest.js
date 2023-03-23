const { ethers } = require("hardhat");
const { use, expect } = require("chai");
const { solidity } = require("ethereum-waffle");

use(solidity);

describe("SolidCircles Minting", function () {
  let myContract;

  // quick fix to let gas reporter fetch data from gas station & coinmarketcap
  before((done) => {
    setTimeout(done, 2000);
  });

  describe("YourCollectible", function () {
    it("Should deploy ArtGenerator and SolidCircles", async function () {
      const ArtGenerator = await ethers.getContractFactory("ArtGenerator");

      const artGenerator = await ArtGenerator.deploy();

      const SolidCircles = await ethers.getContractFactory("SolidCircles");

      const solidCircles = await SolidCircles.deploy(artGenerator.address);

      const amount = await solidCircles.MAX_SOLIDCIRCLES();
      let totalPrice = 0;

      // loop through amount and check final price
      for (let i = 0; i < amount; i++) {
        const price = await solidCircles.PRICE();
        totalPrice += +price;
      }

      console.log("price of #777", totalPrice);
    });
  });
});
