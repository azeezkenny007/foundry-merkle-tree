// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";

/**
 * @title GenerateInput
 * @author Okhamena Azeez
 * @notice A Foundry script that generates JSON input files for Merkle tree creation
 * @dev Creates a structured JSON file with addresses and amounts for airdrop whitelist
 */
contract GenerateInput is Script {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice The amount of tokens each whitelisted address will receive
     * @dev Set to 25 tokens with 18 decimal places
     */
    uint256 private constant AMOUNT = 25 * 1e18;
    
    /**
     * @notice Array defining the data types for the Merkle tree leaves
     * @dev Contains "address" and "uint" types
     */
    string[] types = new string[](2);
    
    /**
     * @notice Counter for the number of whitelisted addresses
     */
    uint256 count;
    
    /**
     * @notice Array of whitelisted addresses for the airdrop
     * @dev These addresses will be included in the Merkle tree
     */
    string[] whitelist = new string[](4);
    
    /**
     * @notice The file path where the generated JSON input will be saved
     */
    string private constant INPUT_PATH = "/script/target/input.json";

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Main execution function that generates the JSON input file
     * @dev Sets up data types, whitelist addresses, creates JSON and writes to file
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

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Creates a JSON string representation of the whitelist data
     * @dev Formats the addresses and amounts into a structured JSON format
     * @return A properly formatted JSON string containing all whitelist data
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
