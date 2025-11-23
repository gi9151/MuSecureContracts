// scripts/deploy-music-only.js
const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log(`Desplegando con: ${deployer.address}`);

  // Usar la dirección existente de SubscriptionManager
  const subscriptionManagerAddress = "0x080A8C0a65f218267f730A0A72e09a110D92E08A";

  const MusicRegistry = await ethers.getContractFactory("MusicRegistry");
  const musicRegistry = await MusicRegistry.deploy(subscriptionManagerAddress);
  await musicRegistry.waitForDeployment();
  
  console.log(`✅ MusicRegistry: ${await musicRegistry.getAddress()}`);
}

main().catch(console.error);