// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.25;

import {VRFCoordinatorV2Interface} from "@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol";
import {VRFConsumerBaseV2} from "@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol";

contract Practice is VRFConsumerBaseV2 {
    error NotEnoughEth();
    error TransferFailed();
    error GameClosed();
    error UpkeepNotNeeded(uint curBalance, uint numPerson, uint gameState);
    // 抽奖状态，在挑选中奖者时不允许参加游戏
    enum GameState {
        OPEN,
        CALCULATING
    }

    uint16 private constant REQUEST_CONFIRMATIONS = 3;
    uint32 private constant NUM_WORDS = 1;
    // 随机数需要用到的参数
    uint private immutable i_entranceFee;
    VRFCoordinatorV2Interface private immutable i_vrfCoordinator;
    bytes32 private immutable i_gasLane;
    uint64 private immutable i_subscriptionId;
    uint32 private immutable i_callbackGasLimit;

    address payable[] private s_plays;
    uint private immutable i_time;
    uint private s_lastTimestamp;
    address private s_lastWinner;
    GameState private s_gameState;

    event EnteredGame(address indexed player);
    event PickedWinner(address indexed winner);

    constructor(
        uint entranceFee,
        uint time,
        address vrfCoordinator,
        bytes32 gasLane,
        uint64 subscriptionId,
        uint32 callbackGasLimit
    ) VRFConsumerBaseV2(vrfCoordinator) {
        i_entranceFee = entranceFee;
        i_time = time;
        i_vrfCoordinator = VRFCoordinatorV2Interface(vrfCoordinator);
        i_gasLane = gasLane;
        i_subscriptionId = subscriptionId;
        i_callbackGasLimit = callbackGasLimit;
        s_gameState = GameState.OPEN;
        s_lastTimestamp = block.timestamp;
    }

    function enterGame() external payable {
        if (msg.value < i_entranceFee) {
            revert NotEnoughEth();
        }
        if (s_gameState != GameState.OPEN) {
            revert GameClosed();
        }
        s_plays.push(payable(msg.sender));

        emit EnteredGame(msg.sender);
    }

    function checkUpkeep(
        bytes memory /* checkData */
    ) public view returns (bool upkeepNeeded, bytes memory /* performData */) {
        bool timePassed = (block.timestamp - s_lastTimestamp) > i_time;
        bool isOpen = s_gameState == GameState.OPEN;
        bool hasBalance = address(this).balance > 0;
        bool hasPlayers = s_plays.length > 0;
        upkeepNeeded = timePassed && isOpen && hasBalance && hasPlayers;
        return (upkeepNeeded, "0x0");
    }

    function performUpkeep(bytes calldata /* performData */) external {
        (bool upkeepNeeded, ) = checkUpkeep("");
        if (!upkeepNeeded) {
            revert UpkeepNotNeeded(
                address(this).balance,
                s_plays.length,
                uint(s_gameState)
            );
        }
        // 说明抽奖间隔还未过去
        if ((block.timestamp - s_lastTimestamp) < i_time) {}

        s_gameState = GameState.CALCULATING;
        // chainlink VRF 随机数
        i_vrfCoordinator.requestRandomWords(
            i_gasLane,
            i_subscriptionId,
            REQUEST_CONFIRMATIONS,
            i_callbackGasLimit,
            NUM_WORDS
        );
    }

    function fulfillRandomWords(
        uint /*requestId*/,
        uint[] memory randomWords
    ) internal override {
        uint winnerIndex = randomWords[0] % s_plays.length;
        s_lastWinner = payable(s_plays[winnerIndex]);
        s_gameState = GameState.OPEN;
        s_plays = new address payable[](0);
        s_lastTimestamp = block.timestamp;
        (bool success, ) = s_lastWinner.call{value: address(this).balance}("");
        if (!success) {
            revert TransferFailed();
        }
        emit PickedWinner(s_plays[winnerIndex]);
    }

    // getter functions
    function getEntranceFee() external view returns (uint) {
        return i_entranceFee;
    }

    function getGameState() external view returns (GameState) {
        return s_gameState;
    }

    function getPlayer(uint playIndex) external view returns (address) {
        return s_plays[playIndex];
    }
}
