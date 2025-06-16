// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirDrop} from "../src/MerkleAirDrop.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";
import {DeployMerkleAirDrop} from "../script/DeployMerkleAirdrop.s.sol";

contract MerkleAirDropTest is ZkSyncChainChecker, Test {
    BagelToken bagelToken;
    MerkleAirDrop merkleAirDrop;
    bytes32 public MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    address gasPayer;
    uint256 userPrivateKey;
    uint256 public constant AMOUNT_TO_CLAIM = 25 * 1e18;
    uint256 public constant AMOUNT_TO_SEND = AMOUNT_TO_CLAIM * 4;
    bytes32 proofOne = 0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a;
    bytes32 proofTwo = 0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576;
    bytes32[] public PROOF = [proofOne, proofTwo];

    function setUp() external {
        if (!isZkSyncChain()) {
            DeployMerkleAirDrop deployMerkleAirdrop = new DeployMerkleAirDrop();
            (bagelToken, merkleAirDrop) = deployMerkleAirdrop.run();
        } else {
            bagelToken = new BagelToken();
            merkleAirDrop = new MerkleAirDrop(MERKLE_ROOT, bagelToken);
            bagelToken.mint(bagelToken.owner(), AMOUNT_TO_SEND);
            bagelToken.transfer(address(merkleAirDrop), AMOUNT_TO_SEND);
        }
        (user, userPrivateKey) = makeAddrAndKey("user");
        (gasPayer) = makeAddr("gasPayer");
        console.log("User:", user);
        console.log("User Private Key:", userPrivateKey);
    }

    function testUserCanClaim() public {
        uint256 startingBalance = bagelToken.balanceOf(user);
        vm.prank(user);
        console.log("User:", user);
        merkleAirDrop.claim(user, AMOUNT_TO_CLAIM, PROOF);
        uint256 endingBalance = bagelToken.balanceOf(user);
        console.log("Ending Balance", endingBalance);
        assertEq(endingBalance, startingBalance + AMOUNT_TO_CLAIM);
    }
}
