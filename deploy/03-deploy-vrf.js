module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const arguments = [
    "0x7a1BaC17Ccc5b313516C5E16fb24f7659aA5ebed",
    "0x4b09e658ed251bcafeebbc69400383d49f344ace09b9576fe248bb02c003fe9f",
    "5413",
    "100000",
    "3",
    "1",
  ];

  const horizonVRF = await deploy("HorizonVRF", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonVRF contract deployed at address: ${horizonVRF.address}`);
};
