// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {MerkleAirDrop} from "../src/MerkleAirDrop.sol";
import {BagelToken} from "../src/BagelToken.sol";

contract MerkleAirDropTest is Test {
    MerkleAirDrop public merkleAirDrop;
    BagelToken public bagelToken;
    bytes32 public constant MERKLE_ROOT = 0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4;
    address user;
    uint256 userPrivateKey;

    function setUp() public {
        bagelToken = new BagelToken();
        merkleAirDrop = new MerkleAirDrop(MERKLE_ROOT,bagelToken);
        (user, userPrivateKey) = makeAddrAndKey("user");
    }

    function testUserCanClaim() external{
        console.log("user address:",user);
    }
}
