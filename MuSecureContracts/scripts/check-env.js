require("dotenv").config();

console.log(" Verificando variables de entorno...");
console.log("PRIVATE_KEY existe?", !!process.env.PRIVATE_KEY);
console.log("PRIVATE_KEY longitud:", process.env.PRIVATE_KEY?.length);
console.log("BASESCAN_API_KEY existe?", !!process.env.BASESCAN_API_KEY);

if (process.env.PRIVATE_KEY) {
  console.log(" PRIVATE_KEY cargada correctamente");
} else {
  console.log(" PRIVATE_KEY NO encontrada");
  console.log(" Asegúrate de que tu archivo .env tenga:");
  console.log("PRIVATE_KEY=tu_private_key_sin_0x");
}