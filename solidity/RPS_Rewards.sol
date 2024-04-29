// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import {Chainlink, ChainlinkClient } from "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RPS_Rewards is ChainlinkClient {
    using Chainlink for Chainlink.Request;

    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    IERC20 public rewardToken;
    string public apiURL;
    mapping(address => uint256) public lastRewardTimestamp;

    constructor(
        address _oracle,
        string memory _jobId,
        uint256 _fee,
        address _rewardToken,
        string memory _apiURL
    ) {
        _setPublicChainlinkToken();
        oracle = _oracle;
        jobId = stringToBytes32(_jobId);
        fee = _fee;
        rewardToken = IERC20(_rewardToken);
        apiURL = _apiURL; // Fixed the redundancy here
    }

    // Function to claim rewards based on RPS throughput
    function claimReward(address user) public {
        require(
            lastRewardTimestamp[user] + 1 days < block.timestamp,
            "only claim rewards once every 24 hours"
        );

        // Request the RPS throughput metrics from the Petals.ml API
        Chainlink.Request memory req = _buildChainlinkRequest(
        jobId,
        address(this),
        this.fulfill.selector
        );

        string memory userAPI_URL = string(abi.encodePacked(apiURL, "?userAddress=", toString(user)));

        req.add("get", userAPI_URL);
        req.add("path", "rpsThroughput"); // specify the API response path for RPS throughput metrics
        req.addInt("times", 100);   // Multiply the result to remove decimal places


        _sendChainlinkRequestTo(oracle, req, fee); // Fixed line 47 here
    }

    // Callback function to recieve the RPS throughput from the API and transfer the calculated reward
    function fulfill(bytes32 _requestId, uint256 _rpsThroughput) public recordChainlinkFulfillment(_requestId) {
        address user = msg.sender;  // Get the user's address from the API response
        uint256 rewardAmount = calculateReward(_rpsThroughput);
        
        // Update the last reward timestamp and transfer the tokens
        lastRewardTimestamp[user] = block.timestamp;
        rewardToken.transfer(user, rewardAmount);
    }

    // Function to calculate the reward amount based on the RPS throughput
    function calculateReward(uint256 rpsThroughput) private pure returns (uint256) {
        // Implement your arbitrary reward calculation logic based on RPS throughput
        return rpsThroughput * 10; 
    }

    // Helper function to convert a string to bytes32
    function stringToBytes32(string memory source) private pure returns (bytes32 result) {
        bytes memory tempEmptyStringTest = bytes(source);
        if (tempEmptyStringTest.length == 0) {
            return 0x0;
        }

        assembly {
            result := mload(add(source, 32))
        }
    }

    // Helper function to convert an Ethereum address to a string
    function toString(address account) public pure returns (string memory) {
        bytes32 value = bytes32(uint256(uint160(account)));
        bytes memory alphabet = "0123456789abcdef";

        bytes memory str = new bytes(42);
        str[0] = '0';
        str[1] = 'x';
        for (uint256 i = 0; i < 20; i++) {
            str[2 + i * 2] = alphabet[uint8(value[i+12] >> 4)];
            str[3 + i * 2] = alphabet[uint8(value[i+12] & 0x0f)];
        }
        return string(str);
    }
}