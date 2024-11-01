// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "./interfaces/IOracle.sol";

contract MintNFTagent {
    address private oracleAddress; // use latest: https://docs.galadriel.com/oracle-address
    IOracle.Message public message;
    string public response;
    IOracle.OpenAiRequest private config;

    constructor(address initialOracleAddress) {
        oracleAddress = initialOracleAddress;

        config = IOracle.OpenAiRequest({
            model : "gpt-4-turbo", // gpt-4-turbo gpt-4o
            frequencyPenalty : 21, // > 20 for null
            logitBias : "", // empty str for null
            maxTokens : 1000, // 0 for null
            presencePenalty : 21, // > 20 for null
            responseFormat : "{\"type\":\"text\"}",
            seed : 0, // null
            stop : "", // null
            temperature : 10, // Example temperature (scaled up, 10 means 1.0), > 20 means null
            topP : 101, // Percentage 0-100, > 100 means null
            tools : "",
            toolChoice : "", // "none" or "auto"
            user : "" // null
        });
    }

    function sendMessage(string memory _message) public {
        string memory prefix ="You are an AI assistant designed to process user requests related to NFTs and blockchain operations. When the user provides a command, you need to identify the intent and extract relevant details. User:Mint an NFT on Avalanche, Expected Output:[{ intent: mint, blockchain: Avalanche }]. Message: ";
        string memory fullMessage = string(abi.encodePacked(prefix, _message));
        message = createTextMessage("user", fullMessage);
        IOracle(oracleAddress).createOpenAiLlmCall(0, config);
    }

    // required for Oracle
    function onOracleOpenAiLlmResponse(
        uint runId,
        IOracle.OpenAiResponse memory _response,
        string memory _errorMessage
    ) public {
        require(msg.sender == oracleAddress, "Caller is not oracle");
        if (bytes(_errorMessage).length > 0) {
            response = _errorMessage;
        } else {
            response = _response.content;
        }
    }

    // required for Oracle
    function getMessageHistory(
        uint /*_runId*/
    ) public view returns (IOracle.Message[] memory) {
        IOracle.Message[] memory messages = new IOracle.Message[](1);
        messages[0] = message;
        return messages;
    }

    // @notice Creates a text message with the given role and content
    // @param role The role of the message
    // @param content The content of the message
    // @return The created message
    function createTextMessage(string memory role, string memory content) private pure returns (IOracle.Message memory) {
        IOracle.Message memory newMessage = IOracle.Message({
        role : role,
        content : new IOracle.Content[](1)
        });
        newMessage.content[0].contentType = "text";
        
        newMessage.content[0].value = content;
        return newMessage;
    }
}