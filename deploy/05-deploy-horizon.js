module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, log } = deployments;
    const { deployer } = await getNamedAccounts();

    const arguments = ["0x70499c328e1e2a3c41108bd3730f6670a44595d1"];
    
    const horizon = await deploy("Horizon", {
        from: deployer,
        args: arguments,
        log: true,
        waitConfirmations: 3,
    });
    
    log(`Horizon contract deployed at address: ${horizon.address}`);
}