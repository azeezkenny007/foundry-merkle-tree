//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {MerkleAirdrop} from "../src/MerkleAirdrop.sol";
import {Script} from "forge-std/Script.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {MerkleProof} from "openzeppelin-contracts/utils/cryptography/MerkleProof.sol";

contract DeployMerkleAirdrop is Script {
    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c47;
    uint256 public constant AMOUNT_TO_TRANSFER = 4 * 25 * 1e18;
    BagelToken bagelToken;
    MerkleAirdrop merkleAirdrop;
    function run() external returns (BagelToken, MerkleAirdrop) {
        vm.startBroadcast();    
        bagelToken = new BagelToken();
        merkleAirdrop = new MerkleAirdrop(MERKLE_ROOT, IERC20(address(bagelToken)));
        bagelToken.mint(bagelToken.owner(), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (bagelToken, merkleAirdrop);
    }
}
