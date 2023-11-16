module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const horizonReceipt = await deploy("HorizonReceiptD", {
    from: deployer,
    log: true,
    waitConfirmations: 3,
  });

  log(
    `HorizonReceiptD contract deployed at address: ${horizonReceipt.address}`
  );
};
