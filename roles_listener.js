const { createAlchemyWeb3 } = require("@alch/alchemy-web3");
const fs = require('fs');
const ethers = require('ethers');

DEPLOYER_ADDRESS = "0x2303C064797bdBc262E37cE64EF1BB87371c5c23";
ALCHEMY_API_KEY = "";

const alchemy_goerli_wss = `wss://eth-goerli.g.alchemy.com/v2/${ALCHEMY_API_KEY}`;
const web3 = createAlchemyWeb3(alchemy_goerli_wss);
let allRoles = ["0x0000000000000000000000000000000000000000000000000000000000000000",// DEFAULT_ADMIN
                "0x75c8926d5f068ebc530646119a6c8b65785c321705e3a39f3f7898e9030b9c80",// FOUNDER
                "0x35a7846a2a701fff6f9d61a46ebff5da578c5dcee8bdf361c569f9ea4ee64771"]// GOVERNANCE
const abiCoder = new ethers.utils.AbiCoder();

async function saveJson(file) {
    fs.writeFile('roles.json', JSON.stringify(file), (err) => {
        if (err) {
            throw err;
        }
    });
}

const OnNewRole = (txn) => {
    let newRole = txn.topics[1]
    if (allRoles.indexOf(newRole) === -1) {
        allRoles.push(newRole);
        saveJson(allRoles);    
        console.log(`ADDED NEW ROLE: ${newRole}`);
    } 
}

async function listenToNationRoles(nation) {
    console.log(`ADDED NATION ROLES LISTENER: ${nation}`);
    let listenerConfig = {
        address: nation,
        topics: ["0xbd79b86ffe0ab8e8776151514217cd7cacd52c909f66475c3af44e129f0b00ff"] // RoleAdminChanged(bytes32,bytes32,bytes32) 
    }
    web3.eth.subscribe("logs", listenerConfig).on("data", OnNewRole);
}

async function listenToDeployer(deployerAddress) {
    let listenerConfig = {
        address: deployerAddress,
        topics: ["0xc8e47eeba0237ce36a0ddf0e952ee6b70f3629ca1e38db09db85d260cd472d44"]//NationStarted(address,address)
    }
    web3.eth.subscribe("logs", listenerConfig).on("data", OnNewNation);
}

const OnNewNation = (txn) => {
    let iface = new ethers.utils.Interface(["event NationStarted(address indexed nation, address indexed founder)"]);
    let res = iface.decodeEventLog("NationStarted", txn.data, txn.topics);
    listenToNationRoles(res.nation);
}

saveJson(allRoles);
listenToDeployer(DEPLOYER_ADDRESS);
