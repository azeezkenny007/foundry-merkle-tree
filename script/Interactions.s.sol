//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirDrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script {
    address claimer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 amount = 25 * 1e18;
    bytes32 PROOF_ONE = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32 PROOF_TWO = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] PROOF = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE =
        hex"d9acab234b1230c3053ba3a3af112668bed4a7013183bb1ea5dff3860f0965ba0efc682bb1abf58dd6322d6753eab8a4a5da69e88a75721796aab9d69658ee301c";

    error InteractionsScript__InvalidSignatureLength();

    function run() external {
        address mostRecentlyDeployedMerkleAirdrop =
            DevOpsTools.get_most_recent_deployment("MerkleAirDrop", block.chainid);
        claimAirdrop(mostRecentlyDeployedMerkleAirdrop);
    }

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

    function claimAirdrop(address _merkleAirdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirDrop(_merkleAirdrop).claim(
            MerkleAirDrop.ClaimParams({claimer: claimer, amount: amount, merkleProof: PROOF, v: v, r: r, s: s})
        );
        vm.stopBroadcast();
    }
}
