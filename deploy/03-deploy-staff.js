// module.exports = async ({ getNamedAccounts, deployments }) => {
//     const { deploy, log } = deployments;
//     const { deployer } = await getNamedAccounts();
    
//     const horizonStaff = await deploy("HorizonStaff", {
//         from: deployer,
//         log: true,
//         waitConfirmations: 3,
//     });
    
//     log(`HorizonStaff contract deployed at address: ${horizonStaff.address}`);
// }