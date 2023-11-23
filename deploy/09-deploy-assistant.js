module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const horizonFujiAssistant = await deploy("HorizonFujiAssistant", {
    from: deployer,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonFujiAssistant contract deployed at address: ${horizonFujiAssistant.address}`);
};
