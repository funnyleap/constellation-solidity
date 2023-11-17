module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const horizonVRF = await deploy("HorizonVRF", {
    from: deployer,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonVRF contract deployed at address: ${horizonVRF.address}`);
};
