// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";

/**
 * @title SplitSignature
 * @author Okhamena Azeez
 * @notice Utility script for splitting ECDSA signatures into their component parts (v, r, s)
 * @dev This script reads a signature from a file and demonstrates how to extract the v, r, s values
 *      that are required for ECDSA signature verification in smart contracts.
 */
contract SplitSignature is Script {
    /**
     * @notice Thrown when the provided signature doesn't have the required 65-byte length
     * @dev ECDSA signatures must be exactly 65 bytes: 32 bytes r + 32 bytes s + 1 byte v
     */
    error __SplitSignatureScript__InvalidSignatureLength();

    /**
     * @notice Splits an ECDSA signature into its v, r, s components
     * @dev Uses inline assembly for efficient memory access to extract signature components.
     *      The signature format is: [32 bytes r][32 bytes s][1 byte v]
     * @param sig The complete ECDSA signature bytes to split
     * @return v The recovery identifier (typically 27 or 28)
     * @return r The first 32 bytes of the signature (x-coordinate of random point)
     * @return s The second 32 bytes of the signature (signature proof)
     */
    function splitSignature(bytes memory sig)
        internal
        pure
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        if (sig.length != 65) {
            revert __SplitSignatureScript__InvalidSignatureLength();
        }

        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
    }

    /**
     * @notice Main execution function that reads a signature file and demonstrates signature splitting
     * @dev Reads signature from "signature.txt", converts it to bytes, splits it into components,
     *      and logs each component for verification and debugging purposes.
     *      
     * Expected file format: Hex-encoded signature string (130 characters for 65 bytes)
     */
    function run() external {
        string memory sig = vm.readFile("signature.txt");
        bytes memory sigBytes = vm.parseBytes(sig);
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(sigBytes);
        console.log("v value:");
        console.log(v);
        console.log("r value:");
        console.logBytes32(r);
        console.log("s value:");
        console.logBytes32(s);
    }
}