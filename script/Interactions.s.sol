//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirDrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

/**
 * @title Interactions
 * @author Okhamena Azeez
 * @notice Script for interacting with deployed MerkleAirDrop contracts to claim airdrops
 * @dev This script demonstrates how to claim an airdrop by providing merkle proofs and ECDSA signatures.
 *      It automatically finds the most recently deployed MerkleAirDrop contract and executes a claim.
 */
contract Interactions is Script {
    /**
     * @notice The address that will claim the airdrop tokens
     */
    address claimer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    
    /**
     * @notice The amount of tokens to claim (25 tokens with 18 decimals)
     */
    uint256 amount = 25 * 1e18;
    
    /**
     * @notice First merkle proof element for validating the claimer's eligibility
     */
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    
    /**
     * @notice Second merkle proof element for validating the claimer's eligibility
     */
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    
    /**
     * @notice Complete merkle proof array containing all proof elements
     */
    bytes32[] PROOF = [PROOF_ONE, PROOF_TWO];
    
    /**
     * @notice ECDSA signature for authorizing the airdrop claim
     * @dev This signature proves that the claimer is authorized to claim the specified amount
     */
    bytes private SIGNATURE =
        hex"d9acab234b1230c3053ba3a3af112668bed4a7013183bb1ea5dff3860f0965ba0efc682bb1abf58dd6322d6753eab8a4a5da69e88a75721796aab9d69658ee301c";

    /**
     * @notice Thrown when the provided signature doesn't have the required 65-byte length
     */
    error InteractionsScript__InvalidSignatureLength();

    /**
     * @notice Main execution function that finds and interacts with the deployed airdrop contract
     * @dev Uses DevOpsTools to locate the most recent MerkleAirDrop deployment and executes a claim
     */
    function run() external {
        address mostRecentlyDeployedMerkleAirdrop =
            DevOpsTools.get_most_recent_deployment("MerkleAirDrop", block.chainid);
        claimAirdrop(mostRecentlyDeployedMerkleAirdrop);
    }

    /**
     * @notice Splits an ECDSA signature into its v, r, s components
     * @dev The signature must be exactly 65 bytes: 32 bytes r + 32 bytes s + 1 byte v
     * @param sig The complete ECDSA signature to split
     * @return v The recovery identifier (27 or 28)
     * @return r The first 32 bytes of the signature
     * @return s The second 32 bytes of the signature
     */
    function splitSignature(bytes memory sig) public pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (sig.length != 65) {
            revert InteractionsScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 96)))
        }
        return (v, r, s);
    }

    /**
     * @notice Claims airdrop tokens from the specified MerkleAirDrop contract
     * @dev Constructs a ClaimParams struct with all required data and calls the claim function
     * @param _merkleAirdrop The address of the MerkleAirDrop contract to claim from
     */
    function claimAirdrop(address _merkleAirdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirDrop(_merkleAirdrop).claim(
            MerkleAirDrop.ClaimParams({claimer: claimer, amount: amount, merkleProof: PROOF, v: v, r: r, s: s})
        );
        vm.stopBroadcast();
    }
}
