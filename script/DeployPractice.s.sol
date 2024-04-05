// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import {Script} from "forge-std/Script.sol";
import {Practice} from "../src/Practice.sol";
import {PracticeConfig} from "../script/PracticeConfig.s.sol";

contract DeployPrctice is Script {
    function run() external returns (Practice, PracticeConfig) {
        PracticeConfig config = new PracticeConfig();
        (
            uint entranceFee,
            uint time,
            address vrfCoordinator,
            bytes32 gasLane,
            uint64 subscriptionId,
            uint32 callbackGasLimit
        ) = config.activeNetworkConfig();

        vm.startBroadcast();
        Practice practice = new Practice(
            entranceFee,
            time,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        );
        vm.stopBroadcast();
        return (practice, config);
    }
}
