// module.exports = async ({ getNamedAccounts, deployments }) => {
//   const { deploy, log } = deployments;
//   const { deployer } = await getNamedAccounts();

//   const fakeRWA = await deploy("FakeRWA", {
//     from: deployer,
//     log: true,
//     waitConfirmations: 3,
//   });

//   log(`FakeRWA contract deployed at address: ${fakeRWA.address}`);
// };
