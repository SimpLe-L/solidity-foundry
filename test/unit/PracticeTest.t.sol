// SPDX-License-Identifier: MIT

pragma solidity ^0.8.25;

import {Test, console} from "forge-std/Test.sol";
import {DeployPrctice} from "../../script/DeployPractice.s.sol";
import {Practice} from "../../src/Practice.sol";
import {PracticeConfig} from "../../script/PracticeConfig.s.sol";

contract PracticeTest is Test {
    Practice practice;
    PracticeConfig config;

    uint entranceFee;
    uint time;
    address vrfCoordinator;
    bytes32 gasLane;
    uint64 subscriptionId;
    uint32 callbackGasLimit;

    address public PLAYER = makeAddr("player");
    uint public constant STARTING_USER_BALANCE = 10 ether;

    function setUp() external {
        DeployPrctice deployer = new DeployPrctice();
        (practice, config) = deployer.run();
        (
            entranceFee,
            time,
            vrfCoordinator,
            gasLane,
            subscriptionId,
            callbackGasLimit
        ) = config.activeNetworkConfig();
        vm.deal(PLAYER, STARTING_USER_BALANCE);
    }

    function testInitializesState() public view {
        assert(practice.getGameState() == Practice.GameState.OPEN);
    }

    // 回滚
    function testPayNotEnough() public {
        vm.prank(PLAYER);
        vm.expectRevert(Practice.NotEnoughEth.selector);
        practice.enterGame();
    }

    function testRecord() public {
        vm.prank(PLAYER);
        practice.enterGame{value: entranceFee}();
        // vm.expectRevert(Practice.NotEnoughEth.selector);
        address playerAddress = practice.getPlayer(0);
        assert(playerAddress == PLAYER);
    }
}
