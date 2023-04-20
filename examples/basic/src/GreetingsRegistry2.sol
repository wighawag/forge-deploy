// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-deploy/proxy/ForgeDeploy_Proxied.sol";

contract GreetingsRegistry2 is Proxied {
    event MessageChanged(
        address indexed user,
        uint256 timestamp,
        string message,
        uint24 dayTimeInSeconds
    );

    struct Message {
        string content;
        uint256 timestamp;
        uint24 dayTimeInSeconds;
    }
    mapping(address => Message) internal _messages;
    string internal _prefix;
    string internal _prefix2;

    constructor(string memory initialPrefix) {
        postUpgrade(initialPrefix);
    }

    function postUpgrade(string memory initialPrefix) public proxied {
        _prefix = initialPrefix;
        _prefix2 = initialPrefix;
    }

    function messages(
        address user
    ) external view returns (Message memory userMsg) {
        userMsg = _messages[user];
    }

    function lastGreetingOf(
        address user
    ) external view returns (string memory greeting) {
        greeting = _messages[user].content;
    }

    function prefix() external view returns (string memory value) {
        return _prefix;
    }

    function setMessage(
        string calldata message,
        uint24 dayTimeInSeconds
    ) external {
        string memory actualMessage = string(
            bytes.concat(bytes(_prefix), bytes(message))
        );
        _messages[msg.sender] = Message({
            content: actualMessage,
            timestamp: block.timestamp,
            dayTimeInSeconds: dayTimeInSeconds
        });
        emit MessageChanged(
            msg.sender,
            block.timestamp,
            actualMessage,
            dayTimeInSeconds
        );
    }
}
