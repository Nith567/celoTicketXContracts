// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {CeloTicketX} from "../src/CeloTicketX.sol";

contract CeloTicketXDeploy is Script {    
    // Contract instance
    CeloTicketX public brokerDemo;
    
    function setUp() public {}
    
    function run() public {
        // Get the private key from the environment
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy the CeloTicketX contract
        brokerDemo = new CeloTicketX();
        console.log("CeloTicketX deployed at:", address(brokerDemo));
        
        vm.stopBroadcast();
    }
} 