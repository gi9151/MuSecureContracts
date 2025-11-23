const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MusicRegistry", function () {
  let MusicRegistry;
  let SubscriptionManager;
  let musicRegistry;
  let subscriptionManager;
  let owner;
  let user1;
  let user2;

  beforeEach(async function () {
    [owner, user1, user2] = await ethers.getSigners();

    SubscriptionManager = await ethers.getContractFactory("SubscriptionManager");
    subscriptionManager = await SubscriptionManager.deploy();
    await subscriptionManager.deployed();

    MusicRegistry = await ethers.getContractFactory("MusicRegistry");
    musicRegistry = await MusicRegistry.deploy(subscriptionManager.address);
    await musicRegistry.deployed();

    await subscriptionManager.setSubscription(user1.address, 1, 30);
  });

  describe("Track Registration", function () {
    it("Should register a new track", async function () {
      const metadataIPFS = "QmMetadataHash123";
      const fingerprint = ethers.utils.toUtf8Bytes("test-fingerprint-data");
      
      await expect(
        musicRegistry.connect(user1).registerTrack(
          "Test Song",
          "Test Artist", 
          "Rock",
          metadataIPFS,
          fingerprint
        )
      ).to.emit(musicRegistry, "TrackRegistered");

      const track = await musicRegistry.getTrack(1);
      expect(track.title).to.equal("Test Song");
      expect(track.artist).to.equal("Test Artist");
      expect(track.owner).to.equal(user1.address);
      expect(track.isRegistered).to.be.true;
    });

    it("Should not register track without active subscription", async function () {
      const metadataIPFS = "QmMetadataHash123";
      const fingerprint = ethers.utils.toUtf8Bytes("test-fingerprint");
      
      await expect(
        musicRegistry.connect(user2).registerTrack(
          "Test Song",
          "Test Artist",
          "Rock", 
          metadataIPFS,
          fingerprint
        )
      ).to.be.revertedWith("No active subscription");
    });

    it("Should not register duplicate fingerprints", async function () {
      const metadataIPFS = "QmMetadataHash123";
      const fingerprint = ethers.utils.toUtf8Bytes("unique-fingerprint");
      
      await musicRegistry.connect(user1).registerTrack(
        "Song 1",
        "Artist 1",
        "Pop",
        metadataIPFS,
        fingerprint
      );

      await expect(
        musicRegistry.connect(user1).registerTrack(
          "Song 2",
          "Artist 2", 
          "Rock",
          metadataIPFS,
          fingerprint
        )
      ).to.be.revertedWith("Fingerprint already exists");
    });
  });

  describe("Track Ownership", function () {
    beforeEach(async function () {
      const metadataIPFS = "QmMetadataHash123";
      const fingerprint = ethers.utils.toUtf8Bytes("test-fingerprint");
      
      await musicRegistry.connect(user1).registerTrack(
        "Test Song",
        "Test Artist",
        "Rock",
        metadataIPFS,
        fingerprint
      );
    });

    it("Should transfer track ownership", async function () {
      await expect(
        musicRegistry.connect(user1).transferOwnership(1, user2.address)
      ).to.emit(musicRegistry, "OwnershipTransferred");

      const track = await musicRegistry.getTrack(1);
      expect(track.owner).to.equal(user2.address);
    });

    it("Should not allow non-owner to transfer ownership", async function () {
      await expect(
        musicRegistry.connect(user2).transferOwnership(1, user2.address)
      ).to.be.revertedWith("Not track owner");
    });

    it("Should verify ownership correctly", async function () {
      expect(await musicRegistry.verifyOwnership(1, user1.address)).to.be.true;
      expect(await musicRegistry.verifyOwnership(1, user2.address)).to.be.false;
    });
  });
});