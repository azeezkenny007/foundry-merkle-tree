// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirDrop} from "../src/MerkleAirDrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirDropTest is Test {
    BagelToken public bagelToken;
    MerkleAirDrop public merkleAirDrop;
    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivateKey;
    uint256 public constant AMOUNT= 25 * 1e18;
    bytes32[] public PROOF = [0x0fd7c981d39bece61f7499702bf59b3114a90e66b51ba2c53abdf7b62986c00a,0xe5ebd1e1b5a5478a944ecab36a9a954ac3b6b8216875f6524caa7a1d87096576]; 
   
    function setUp() external {
        bagelToken = new BagelToken();
        merkleAirDrop = new MerkleAirDrop(MERKLE_ROOT,bagelToken);
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function testUserCanClaim() external {
        uint256 startingBalance = bagelToken.balanceOf(user);
        vm.prank(user);
        merkleAirDrop.claim(user, AMOUNT, PROOF);

    }
}
