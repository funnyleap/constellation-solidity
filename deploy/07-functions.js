module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const arguments = ["0xA9d587a00A31A52Ed70D6026794a8FC5E2F5dCb0"];

  const horizonFunctions = await deploy("HorizonFunctions", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonFunctions contract deployed at address: ${horizonFunctions.address}`);
};
