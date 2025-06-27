// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";

/**
 * @title SplitSignature
 * @author Okhamena Azeez
 * @notice A Foundry script for splitting ECDSA signatures into their v, r, s components
 * @dev This script reads a signature from a file and splits it into its cryptographic components
 */
contract SplitSignature is Script {
    /*//////////////////////////////////////////////////////////////
                               ERRORS
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice Thrown when the signature length is not exactly 65 bytes
     */
    error __SplitSignatureScript__InvalidSignatureLength();

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Splits an ECDSA signature into its v, r, s components
     * @dev Uses inline assembly for efficient byte manipulation
     * @param sig The signature bytes to split (must be 65 bytes)
     * @return v The recovery id (1 byte)
     * @return r The first 32 bytes of the signature
     * @return s The second 32 bytes of the signature
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

    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Main execution function for the script
     * @dev Reads signature from "signature.txt" file and logs the split components
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