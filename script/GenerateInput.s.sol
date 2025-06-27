// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateInput
 * @author Okhamena Azeez
 * @notice Generates JSON input file for merkle tree creation with predefined whitelist addresses
 * @dev This script creates a properly formatted JSON file that can be consumed by MakeMerkle.s.sol
 *      to generate merkle proofs. The JSON contains address-amount pairs for eligible airdrop recipients.
 */
contract GenerateInput is Script {
    /**
     * @notice The standard airdrop amount per eligible address (25 tokens with 18 decimals)
     */
    uint256 private constant AMOUNT = 25 * 1e18;
    
    /**
     * @notice Array defining the data types for merkle tree leaf nodes
     * @dev First element is "address", second is "uint" representing the token amount
     */
    string[] types = new string[](2);
    
    /**
     * @notice Counter for the number of whitelisted addresses
     */
    uint256 count;
    
    /**
     * @notice Array of whitelisted addresses eligible for the airdrop
     * @dev These addresses will be included in the merkle tree generation
     */
    string[] whitelist = new string[](4);
    
    /**
     * @notice The file path where the JSON input will be written
     */
    string private constant INPUT_PATH = "/script/target/input.json";

    /**
     * @notice Main execution function that generates the JSON input file
     * @dev Initializes the whitelist with predefined addresses and creates a JSON file
     *      containing all necessary data for merkle tree generation
     */
    function run() public {
        types[0] = "address";
        types[1] = "uint";
        whitelist[0] = "0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D";
        whitelist[1] = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
        whitelist[2] = "0x2ea3970Ed82D5b30be821FAAD4a731D35964F7dd";
        whitelist[3] = "0xf6dBa02C01AF48Cf926579F77C9f874Ca640D91D";
        count = whitelist.length;
        string memory input = _createJSON();
        // write to the output file the stringified output json tree dump
        vm.writeFile(string.concat(vm.projectRoot(), INPUT_PATH), input);

        console.log("DONE: The output is found at %s", INPUT_PATH);
    }

    /**
     * @notice Creates a properly formatted JSON string for merkle tree input
     * @dev Constructs a JSON object containing:
     *      - types: Array of data types for each merkle leaf
     *      - count: Number of entries in the whitelist
     *      - values: Object mapping indices to address-amount pairs
     * @return A JSON string ready for file output and merkle tree generation
     */
    function _createJSON() internal view returns (string memory) {
        string memory countString = vm.toString(count); // convert count to string
        string memory amountString = vm.toString(AMOUNT); // convert amount to string
        string memory json = string.concat('{ "types": ["address", "uint"], "count":', countString, ',"values": {');
        for (uint256 i = 0; i < whitelist.length; i++) {
            if (i == whitelist.length - 1) {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    whitelist[i],
                    '"',
                    ', "1":',
                    '"',
                    amountString,
                    '"',
                    " }"
                );
            } else {
                json = string.concat(
                    json,
                    '"',
                    vm.toString(i),
                    '"',
                    ': { "0":',
                    '"',
                    whitelist[i],
                    '"',
                    ', "1":',
                    '"',
                    amountString,
                    '"',
                    " },"
                );
            }
        }
        json = string.concat(json, "} }");

        return json;
    }
}
