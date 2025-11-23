const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
 
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? "base-sepolia" : network.name;
  
  console.log(` Iniciando deployment de MuSecureP1 en {networkName.toUpperCase()}...`);
  console.log("");
  
  const [deployer] = await ethers.getSigners();
  console.log(` Desplegando con la cuenta: {deployer.address}`);
  
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log(` Balance: {ethers.utils.formatEther(balance)} ETH`);
  
  
  if (networkName !== "localhost" && balance.lt(ethers.utils.parseEther("0.01"))) {
    throw new Error(" Balance insuficiente. Obtén ETH de test de: https://faucet.circle.com/");
  }

  try {
   
    console.log("\n  Desplegando SubscriptionManager...");
    const SubscriptionManager = await ethers.getContractFactory("SubscriptionManager");
    const subscriptionManager = await SubscriptionManager.deploy();
    await subscriptionManager.deployed();
    console.log(" SubscriptionManager:", subscriptionManager.address);
    
    console.log("\n  Desplegando MusicRegistry...");
    const MusicRegistry = await ethers.getContractFactory("MusicRegistry");
    const musicRegistry = await MusicRegistry.deploy(subscriptionManager.address);
    await musicRegistry.deployed();
    console.log(" MusicRegistry:", musicRegistry.address);
    
    
    console.log("\n Guardando direcciones de contratos...");
    const contracts = {
      subscriptionManager: subscriptionManager.address,
      musicRegistry: musicRegistry.address,
      network: networkName,
      deployer: deployer.address,
      timestamp: new Date().toISOString(),
      blockExplorer: networkName === "base-sepolia" ? "https://base-sepolia.blockscout.com/" : "localhost"
    };
    
    const deploymentsDir = path.join(__dirname, "..", "deployments");
    if (!fs.existsSync(deploymentsDir)) {
      fs.mkdirSync(deploymentsDir, { recursive: true });
    }
    
    const deploymentFile = path.join(deploymentsDir, `deployment-{networkName}-{Date.now()}.json`);
    fs.writeFileSync(deploymentFile, JSON.stringify(contracts, null, 2));
    console.log(" Deployment guardado en:", deploymentFile);
    
   
    console.log(`\n ¡Deployment en {networkName.toUpperCase()} completado!`);
    console.log("===========================================");
    console.log(" Contratos desplegados:");
    console.log(`   • SubscriptionManager: {subscriptionManager.address}`);
    console.log(`   • MusicRegistry: {musicRegistry.address}`);
    
    if (networkName === "base-sepolia") {
      console.log("\n Verificar en BaseScan:");
      console.log(`   https://base-sepolia.blockscout.com/address/${subscriptionManager.address}`);
      console.log(`   https://base-sepolia.blockscout.com/address/${musicRegistry.address}`);
    }
    
  } catch (error) {
    console.error(" Error en deployment:", error);
    process.exit(1);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(" Error:", error);
    process.exit(1);
  });