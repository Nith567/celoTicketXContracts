// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.19;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {CeloTicketX} from "../src/CeloTicketX.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Metadata} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

contract CeloTicketXScript is Script {
    address public constant CeloTicket = 0xcBf795cbD25104eDF9431473935958aA066338BB;

    function setUp() public {}

    function run() public {
        // Get the private key from the environment
        uint256 userPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(userPrivateKey);
        // Get the broker contract instance
        CeloTicketX demo = CeloTicketX(CeloTicket);

        // Get token addresses
        address CJPY = demo.JPY();
        address cUSD = demo.CUSD();
        console.log("CJPY address:", CJPY);
        console.log("cUSD address:", cUSD);

        // Get the user's address
        address user = vm.addr(userPrivateKey);
        console.log("User address:", user);

        // Get initial balances
        uint256 initialCJPYBalance = IERC20Metadata(CJPY).balanceOf(user);
        uint256 initialcUSDBalance = IERC20Metadata(cUSD).balanceOf(user);
        console.log("Initial CJPY balance:", initialCJPYBalance);
        console.log("Initial cUSD balance:", initialcUSDBalance);

        // User 1 (event creator) lists an event with price 5e15
        string memory eventName = "brazilHotel";
        string memory eventDetails="ipfs://bafkreihv536dl4wjsrekyo3baclqyls75kozgc3jposl5x5yr3zyem5guq";
        uint256 pricePerPerson = 3e15;
        string memory ipfsImageUrl = "ipfs://bafkreiaijjzijufrqbsxbgtrssvtacjzkclrzsmbysd5zxd6qqdb4rzcye";
        demo.createEvent(eventName, eventDetails, pricePerPerson, ipfsImageUrl);
        console.log("Created event:", eventName);

        // Get the eventId (should be demo.eventCounter() - 1)
        uint256 eventId = demo.eventCounter() - 1;
        console.log("Event ID:", eventId);

        vm.stopBroadcast();

        // User 2 (tourist) pays for tickets using CJPY
        uint256 user2PrivateKey = vm.envUint("PRIVATE_KEY_U2");
        address user2 = vm.addr(user2PrivateKey);
        vm.startBroadcast(user2PrivateKey);
        uint256 initialCJPYBalanceUser2 = IERC20Metadata(CJPY).balanceOf(user2);
        console.log("User2 address:", user2);
        console.log("Initial CJPY balance (User2):", initialCJPYBalanceUser2);

        uint256 quantity = 1;
        address paymentToken = CJPY;
        IERC20Metadata(paymentToken).approve(CeloTicket, type(uint256).max);
        demo.buyTicket(eventId, quantity, paymentToken);
        console.log("User2 bought tickets for event using CJPY");

        // Fetch the NFT contract address from CeloTicketX
        address nftAddress = address(demo.nftMinter());
        console.log("NFT contract address:", nftAddress);

        // Query the user's NFT balance
        uint256 nftBalance = IERC721(nftAddress).balanceOf(user2);
        console.log("User2 NFT balance after mint:", nftBalance);

        // If at least one NFT, print the tokenURI for the latest minted token
        if (nftBalance > 0) {
            uint256 tokenId = nftBalance; // This assumes sequential minting and no burns
            string memory uri = IERC721Metadata(nftAddress).tokenURI(tokenId);
            console.log("TokenURI for latest ticket (User2):", uri);
        }

        // Get final balances for user2
        uint256 finalCJPYBalanceUser2 = IERC20Metadata(CJPY).balanceOf(user2);
        console.log("Final CJPY balance (User2):", finalCJPYBalanceUser2);
        console.log("CJPY net change (User2):", int256(finalCJPYBalanceUser2) - int256(initialCJPYBalanceUser2));
        vm.stopBroadcast();

        // Get final balances for user
        uint256 finalCJPYBalanceUser = IERC20Metadata(CJPY).balanceOf(user);
        uint256 finalcUSDBalance = IERC20Metadata(cUSD).balanceOf(user);
        console.log("Final CJPY balance:", finalCJPYBalanceUser);
        console.log("Final cUSD balance:", finalcUSDBalance);
        console.log("CJPY net change:", int256(finalCJPYBalanceUser) - int256(initialCJPYBalance));
        console.log("cUSD net change:", int256(finalcUSDBalance) - int256(initialcUSDBalance));
    }
}

