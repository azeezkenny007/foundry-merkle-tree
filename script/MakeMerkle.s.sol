// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {stdJson} from "forge-std/StdJson.sol";
import {console} from "forge-std/console.sol";
import {Merkle} from "murky/src/Merkle.sol";
import {ScriptHelper} from "murky/script/common/ScriptHelper.sol";

/**
 * @title MakeMerkle
 * @author Okhamena Azeez
 * @notice A Foundry script that generates Merkle proofs and trees for airdrop verification
 * @dev To use this script:
 *      1. Run `forge script script/GenerateInput.s.sol` to generate the input file
 *      2. Run `forge script script/MakeMerkle.s.sol`
 *      3. The output file will be generated in /script/target/output.json
 * 
 * Original Work inspired by:
 * @author kootsZhin
 * @notice https://github.com/dmfxyz/murky
 */
contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string; // enables us to use the json cheatcodes for strings

    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Instance of the Merkle contract from Murky library
     * @dev Used for generating Merkle trees and proofs
     */
    Merkle private m = new Merkle();

    /**
     * @notice Path to the input JSON file containing whitelist data
     */
    string private inputPath = "/script/target/input.json";
    
    /**
     * @notice Path where the output JSON file will be generated
     */
    string private outputPath = "/script/target/output.json";

    /**
     * @notice Raw JSON content read from the input file
     */
    string private elements = vm.readFile(string.concat(vm.projectRoot(), inputPath));
    
    /**
     * @notice Array of data types for Merkle tree leaves (from JSON)
     */
    string[] private types = elements.readStringArray(".types");
    
    /**
     * @notice Number of leaf nodes in the Merkle tree
     */
    uint256 private count = elements.readUint(".count");

    /**
     * @notice Array to store the computed leaf hashes
     */
    bytes32[] private leafs = new bytes32[](count);

    /**
     * @notice Array to store stringified input data for each leaf
     */
    string[] private inputs = new string[](count);
    
    /**
     * @notice Array to store the final JSON output for each proof
     */
    string[] private outputs = new string[](count);

    /**
     * @notice Final concatenated output string
     */
    string private output;

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Constructs the JSON path for accessing values by index
     * @dev Returns the path ".values.{i}.{j}" for accessing nested JSON values
     * @param i The outer index (leaf node index)
     * @param j The inner index (field index within the leaf)
     * @return The constructed JSON path string
     */
    function getValuesByIndex(uint256 i, uint256 j) internal pure returns (string memory) {
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    }

    /**
     * @notice Generates JSON entries for the output file
     * @dev Creates a structured JSON object containing inputs, proof, root, and leaf data
     * @param _inputs Stringified input data for the leaf
     * @param _proof Stringified Merkle proof array
     * @param _root Stringified Merkle root hash
     * @param _leaf Stringified leaf hash
     * @return Formatted JSON string for the entry
     */
    function generateJsonEntries(string memory _inputs, string memory _proof, string memory _root, string memory _leaf)
        internal
        pure
        returns (string memory)
    {
        string memory result = string.concat(
            "{",
            "\"inputs\":",
            _inputs,
            ",",
            "\"proof\":",
            _proof,
            ",",
            "\"root\":\"",
            _root,
            "\",",
            "\"leaf\":\"",
            _leaf,
            "\"",
            "}"
        );

        return result;
    }

    /*//////////////////////////////////////////////////////////////
                            PUBLIC FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Main execution function that reads input, generates Merkle proofs, and writes output
     * @dev Processes each whitelist entry, creates leaf hashes, generates proofs, and outputs JSON
     */
    function run() public {
        console.log("Generating Merkle Proof for %s", inputPath);

        for (uint256 i = 0; i < count; ++i) {
            string[] memory input = new string[](types.length); // stringified data (address and string both as strings)
            bytes32[] memory data = new bytes32[](types.length); // actual data as a bytes32

            for (uint256 j = 0; j < types.length; ++j) {
                if (compareStrings(types[j], "address")) {
                    address value = elements.readAddress(getValuesByIndex(i, j));
                    // you can't immediately cast straight to 32 bytes as an address is 20 bytes so first cast to uint160 (20 bytes) cast up to uint256 which is 32 bytes and finally to bytes32
                    data[j] = bytes32(uint256(uint160(value)));
                    input[j] = vm.toString(value);
                } else if (compareStrings(types[j], "uint")) {
                    uint256 value = vm.parseUint(elements.readString(getValuesByIndex(i, j)));
                    data[j] = bytes32(value);
                    input[j] = vm.toString(value);
                }
            }
            // Create the hash for the merkle tree leaf node
            // abi encode the data array (each element is a bytes32 representation for the address and the amount)
            // Helper from Murky (ltrim64) Returns the bytes with the first 64 bytes removed
            // ltrim64 removes the offset and length from the encoded bytes. There is an offset because the array
            // is declared in memory
            // hash the encoded address and amount
            // bytes.concat turns from bytes32 to bytes
            // hash again because preimage attack
            leafs[i] = keccak256(bytes.concat(keccak256(ltrim64(abi.encode(data)))));
            // Converts a string array into a JSON array string.
            // store the corresponding values/inputs for each leaf node
            inputs[i] = stringArrayToString(input);
        }

        for (uint256 i = 0; i < count; ++i) {
            // get proof gets the nodes needed for the proof & stringify (from helper lib)
            string memory proof = bytes32ArrayToString(m.getProof(leafs, i));
            // get the root hash and stringify
            string memory root = vm.toString(m.getRoot(leafs));
            // get the specific leaf working on
            string memory leaf = vm.toString(leafs[i]);
            // get the singified input (address, amount)
            string memory input = inputs[i];

            // generate the Json output file (tree dump)
            outputs[i] = generateJsonEntries(input, proof, root, leaf);
        }

        // stringify the array of strings to a single string
        output = stringArrayToArrayString(outputs);
        // write to the output file the stringified output json (tree dump)
        vm.writeFile(string.concat(vm.projectRoot(), outputPath), output);

        console.log("DONE: The output is found at %s", outputPath);
    }
}
