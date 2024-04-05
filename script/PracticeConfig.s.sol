// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {VRFCoordinatorV2Mock} from "@chainlink/contracts/src/v0.8/mocks/VRFCoordinatorV2Mock.sol";

contract PracticeConfig is Script {
    struct NetworkConfig {
        uint entranceFee;
        uint time;
        address vrfCoordinator;
        bytes32 gasLane;
        uint64 subscriptionId;
        uint32 callbackGasLimit;
    }
    NetworkConfig public activeNetworkConfig;

    constructor() {
        if (block.chainid == 1115111) {
            activeNetworkConfig = getSepoliaConfig();
        } else {
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSepoliaConfig() public pure returns (NetworkConfig memory) {
        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                time: 30,
                vrfCoordinator: 0x8103B0A8A00be2DDC778e6e7eaa21791Cd364625,
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000
            });
    }

    // 在本地Anvil测试，需要自己部署相应的合约
    function getAnvilConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.vrfCoordinator != address(0)) {
            return activeNetworkConfig;
        }

        uint96 baseFee = 0.25 ether; // 0.25 LINK
        uint96 gasPriceLink = 1e9; // 1 gwei

        vm.startBroadcast();
        VRFCoordinatorV2Mock vrf = new VRFCoordinatorV2Mock(
            baseFee,
            gasPriceLink
        );
        vm.stopBroadcast();

        return
            NetworkConfig({
                entranceFee: 0.01 ether,
                time: 30,
                vrfCoordinator: address(vrf),
                gasLane: 0x474e34a077df58807dbe9c96d3c009b23b3c6d0cce433e59bbf5b34f823bc56c,
                subscriptionId: 0,
                callbackGasLimit: 500000
            });
    }
}
