const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("SubscriptionManager", function () {
  let SubscriptionManager;
  let subscriptionManager;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();
    
    SubscriptionManager = await ethers.getContractFactory("SubscriptionManager");
    subscriptionManager = await SubscriptionManager.deploy();
    await subscriptionManager.deployed();
  });

  describe("Deployment", function () {
    it("Should set the right owner", async function () {
      expect(await subscriptionManager.owner()).to.equal(owner.address);
    });

    it("Should initialize tier features correctly", async function () {
      const freeFeatures = await subscriptionManager.tierFeatures(0);
      expect(freeFeatures.metadataIPFS).to.be.true;
      expect(freeFeatures.audioIPFS).to.be.false;
      expect(freeFeatures.permanentStorage).to.be.false;
      expect(freeFeatures.maxFingerprintSize).to.equal(1024);

      const proFeatures = await subscriptionManager.tierFeatures(1);
      expect(proFeatures.audioIPFS).to.be.true;
      expect(proFeatures.permanentStorage).to.be.false;

      const goldFeatures = await subscriptionManager.tierFeatures(2);
      expect(goldFeatures.audioIPFS).to.be.true;
      expect(goldFeatures.permanentStorage).to.be.true;
    });
  });

  describe("Subscription Management", function () {
    it("Should set subscription for user", async function () {
      await subscriptionManager.setSubscription(user1.address, 1, 30);
      
      const userSub = await subscriptionManager.getUserSubscription(user1.address);
      expect(userSub.user).to.equal(user1.address);
      expect(userSub.tier).to.equal(1);
      expect(userSub.isActive).to.be.true;
    });

    it("Should allow only owner to set tier features", async function () {
      await subscriptionManager.setTierFeatures(0, {
        metadataIPFS: true,
        fingerprintOnchain: true,
        audioIPFS: false,
        permanentStorage: false,
        maxFingerprintSize: 2048
      });

      await expect(
        subscriptionManager.connect(user1).setTierFeatures(0, {
          metadataIPFS: true,
          fingerprintOnchain: true,
          audioIPFS: false,
          permanentStorage: false,
          maxFingerprintSize: 2048
        })
      ).to.be.revertedWith("Only owner can call this");
    });

    it("Should check subscription permissions correctly", async function () {
      expect(await subscriptionManager.canStoreAudioIPFS(user1.address)).to.be.false;

      await subscriptionManager.setSubscription(user1.address, 1, 30);
      
      expect(await subscriptionManager.canStoreAudioIPFS(user1.address)).to.be.true;
      expect(await subscriptionManager.canUsePermanentStorage(user1.address)).to.be.false;
    });
  });
});