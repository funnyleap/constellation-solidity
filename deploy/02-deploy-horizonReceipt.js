// module.exports = async ({ getNamedAccounts, deployments }) => {
//   const { deploy, log } = deployments;
//   const { deployer } = await getNamedAccounts();

//   const horizonReceipt = await deploy("HorizonReceipt", {
//     from: deployer,
//     log: true,
//     waitConfirmations: 3,
//   });

//   log(`HorizonReceipt contract deployed at address: ${horizonReceipt.address}`);
// };

