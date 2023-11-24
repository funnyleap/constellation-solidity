module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const arguments = [
    "0x554472a2720e5e7d5d3c817529aba05eed5f82d8",
    "0x0b9d5D9136855f6FEc3c0993feE6E9CE8a297846",
  ];

  const horizonFujiS = await deploy("HorizonFujiS", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonFujiS contract deployed at address: ${horizonFujiS.address}`);
};
