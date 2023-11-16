module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const arguments = ["0x554472a2720e5e7d5d3c817529aba05eed5f82d8"];

  const horizonFujiR = await deploy("HorizonFujiR", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonFujiR contract deployed at address: ${horizonFujiR.address}`);
};
