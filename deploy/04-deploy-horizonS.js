module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();

  const arguments = [
    "0x70499c328e1e2a3c41108bd3730f6670a44595d1",
    "0x326C977E6efc84E512bB9C30f76E30c160eD06FB",
  ];

  const horizonS = await deploy("HorizonS", {
    from: deployer,
    args: arguments,
    log: true,
    waitConfirmations: 3,
  });

  log(`HorizonS contract deployed at address: ${horizonS.address}`);
};
