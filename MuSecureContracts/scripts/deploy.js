// scripts/deploy-music-only-fixed.js
const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
  const network = await ethers.provider.getNetwork();
  const networkName = network.name === "unknown" ? "localhost" : network.name;
  
  console.log(`\n Desplegando solo MusicRegistry en ${networkName.toUpperCase()}...\n`);

  const [deployer] = await ethers.getSigners();
  const balance = await ethers.provider.getBalance(deployer.address);
  
  console.log(` Desplegando con la cuenta: ${deployer.address}`);
  console.log(` Balance: ${ethers.formatEther(balance)} ETH\n`);

  // Usar la dirección del SubscriptionManager que YA está desplegada
  const subscriptionManagerAddress = "0x3B5080230FBFDD4cEE947067140B4a6C69149Cf2";
  console.log(` Usando SubscriptionManager existente: ${subscriptionManagerAddress}`);

  console.log(" Desplegando MusicRegistry...");
  const MusicRegistry = await ethers.getContractFactory("MusicRegistry");
  
  //  Pasar la dirección existente del SubscriptionManager
  const musicRegistry = await MusicRegistry.deploy(subscriptionManagerAddress);
  await musicRegistry.waitForDeployment();
  const musicRegistryAddress = await musicRegistry.getAddress();
  console.log(` MusicRegistry: ${musicRegistryAddress}`);

  // Guardar en archivo
  const deploymentInfo = {
    network: networkName,
    chainId: network.chainId,
    timestamp: new Date().toISOString(),
    contracts: {
      SubscriptionManager: subscriptionManagerAddress,
      MusicRegistry: musicRegistryAddress
    },
    deployer: deployer.address
  };

  const deploymentsDir = path.join(__dirname, "..", "deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }

  const deploymentFile = path.join(deploymentsDir, `deployment-${networkName}-${Date.now()}.json`);
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  
  console.log(`\n Deployment guardado en: ${deploymentFile}`);
  console.log(`\n ¡MusicRegistry desplegado en ${networkName.toUpperCase()}!`);
  console.log("===========================");
  console.log(" Direcciones:");
  console.log(`   • SubscriptionManager: ${subscriptionManagerAddress}`);
  console.log(`   • MusicRegistry: ${musicRegistryAddress}`);

  if (networkName === "base-sepolia") {
    console.log("\n Verificar en BaseScan:");
    console.log(`   https://sepolia.basescan.org/address/${subscriptionManagerAddress}`);
    console.log(`   https://sepolia.basescan.org/address/${musicRegistryAddress}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(" Error en el deployment:", error);
    process.exit(1);
  });