//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {MerkleAirDrop} from "../src/MerkleAirdrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {DevOpsTools} from "foundry-devops/src/DevOpsTools.sol";

contract Interactions is Script {
    address claimer = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
    uint256 amount = 25 * 1e18;
    bytes32 PROOF_ONE = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    bytes32 PROOF_TWO = 0xd1445c931158119b00449ffcac3c947d028c0c359c34a6646d95962b3b55c6ad;
    bytes32[] PROOF = [PROOF_ONE, PROOF_TWO];
    bytes private SIGNATURE =
        hex"95c2de964f19cf64387aea722325372489d657047757553f69cf5663d1b288f15abd72033ae8668c6f34ad1325a09226ad7e699a75f4f09e515518412eadf5e91c";

    function run() external {
        address mostRecentlyDeployedMerkleAirdrop =
            DevOpsTools.get_most_recent_deployment("MerkleAirdrop", block.chainid);
        claimAirdrop(mostRecentlyDeployedMerkleAirdrop);
    }

    function splitSignature(bytes memory sig) public returns (uint8, bytes32, bytes32) {
        if (sig.length != 65) {
            revert InteractionsScript__InvalidSignatureLength();
        }
        assembly {
            r := mload(add(sig, 32))
            s := mload(add(sig, 64))
            v := byte(0, mload(add(sig, 65)))
        }
        return (v, r, s);
    }

    function claimAirdrop(address _merkleAirdrop) public {
        vm.startBroadcast();
        (uint8 v, bytes32 r, bytes32 s) = splitSignature(SIGNATURE);
        MerkleAirDrop(_merkleAirdrop).claim(
            MerkleAirDrop.ClaimParams({claimer: claimer, amount: amount, merkleProof: PROOF, v: 0, r: 0, s: 0})
        );
        vm.stopBroadcast();
    }
}
