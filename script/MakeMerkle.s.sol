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
 * @author Ciara Nightingale
 * @author Cyfrin
 * @notice Generates merkle proofs and output file from input JSON data for airdrop validation
 * @dev This script reads an input JSON file containing addresses and amounts, creates a merkle tree,
 *      and generates proofs for each entry. The output file contains all necessary data for airdrop claims.
 *
 * Usage Instructions:
 * 1. Run `forge script script/GenerateInput.s.sol` to generate the input file
 * 2. Run `forge script script/MakeMerkle.s.sol` to generate merkle proofs
 * 3. The output file will be generated in /script/target/output.json
 *
 * Original Work by:
 * @author kootsZhin
 * @notice https://github.com/dmfxyz/murky
 */
contract MakeMerkle is Script, ScriptHelper {
    using stdJson for string; // enables us to use the json cheatcodes for strings

    /**
     * @notice Instance of the Merkle contract from Murky library for tree operations
     */
    Merkle private m = new Merkle();

    /**
     * @notice Path to the input JSON file containing addresses and amounts
     */
    string private inputPath = "/script/target/input.json";
    
    /**
     * @notice Path where the output JSON file with proofs will be written
     */
    string private outputPath = "/script/target/output.json";

    /**
     * @notice Raw JSON content read from the input file
     */
    string private elements = vm.readFile(string.concat(vm.projectRoot(), inputPath));
    
    /**
     * @notice Array of data types for merkle tree leaf nodes (e.g., ["address", "uint"])
     */
    string[] private types = elements.readStringArray(".types");
    
    /**
     * @notice Number of entries/leaf nodes in the merkle tree
     */
    uint256 private count = elements.readUint(".count");

    /**
     * @notice Array of hashed leaf values for the merkle tree
     */
    bytes32[] private leafs = new bytes32[](count);

    /**
     * @notice Array of stringified input values for each leaf node
     */
    string[] private inputs = new string[](count);
    
    /**
     * @notice Array of JSON strings containing proof data for each leaf
     */
    string[] private outputs = new string[](count);

    /**
     * @notice Final JSON output string containing all proofs and metadata
     */
    string private output;

    /**
     * @notice Constructs the JSON path for accessing input values by index
     * @dev Returns path in format ".values.{i}.{j}" for accessing nested JSON values
     * @param i The entry index (which address/amount pair)
     * @param j The field index (0 for address, 1 for amount)
     * @return The JSON path string for accessing the specified value
     */
    function getValuesByIndex(uint256 i, uint256 j) internal pure returns (string memory) {
        return string.concat(".values.", vm.toString(i), ".", vm.toString(j));
    }

    /**
     * @notice Generates a JSON object containing proof data for a single merkle leaf
     * @dev Creates a JSON string with inputs, proof array, root hash, and leaf hash
     * @param _inputs Stringified array of input values (address, amount)
     * @param _proof Stringified array of merkle proof hashes
     * @param _root The merkle root hash as a string
     * @param _leaf The specific leaf hash as a string
     * @return A JSON string containing all proof-related data for one entry
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

    /**
     * @notice Main execution function that processes input data and generates merkle proofs
     * @dev Performs the following steps:
     *      1. Reads and parses input JSON file
     *      2. Creates leaf hashes for each address-amount pair  
     *      3. Generates merkle proofs for each leaf
     *      4. Writes comprehensive output file with all proof data
     * 
     * The process involves double hashing for security:
     * - First hash: keccak256(abi.encode(address, amount))
     * - Second hash: keccak256(firstHash) to prevent preimage attacks
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
