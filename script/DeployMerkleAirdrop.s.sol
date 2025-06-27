//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {MerkleAirDrop,IERC20} from "../src/MerkleAirDrop.sol"; // Fixed case in file name
import {Script} from "forge-std/Script.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

/**
 * @title DeployMerkleAirDrop
 * @author Okhamena Azeez
 * @notice A Foundry deployment script for the MerkleAirDrop system
 * @dev Deploys BagelToken and MerkleAirDrop contracts, mints tokens and transfers them to the airdrop contract
 */
contract DeployMerkleAirDrop is Script {
    /*//////////////////////////////////////////////////////////////
                            STATE VARIABLES
    //////////////////////////////////////////////////////////////*/
    
    /**
     * @notice The Merkle root hash for the airdrop whitelist
     * @dev This root is used to verify airdrop claims
     */
    bytes32 public MERKLE_ROOT = bytes32(0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4);
    
    /**
     * @notice Total amount of tokens to transfer to the airdrop contract
     * @dev Calculated as 4 users * 25 tokens * 1e18 (18 decimals)
     */
    uint256 public constant AMOUNT_TO_TRANSFER = 4 * 25 * 1e18;
    
    /*//////////////////////////////////////////////////////////////
                            EXTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Main deployment function
     * @dev Deploys BagelToken and MerkleAirDrop contracts, mints tokens and funds the airdrop
     * @return bagelToken The deployed BagelToken contract instance
     * @return merkleAirdrop The deployed MerkleAirDrop contract instance
     */
    function run() external returns (BagelToken, MerkleAirDrop) { 
        vm.startBroadcast();
        BagelToken bagelToken = new BagelToken();
        MerkleAirDrop merkleAirdrop = new MerkleAirDrop(MERKLE_ROOT, IERC20((bagelToken)));
        bagelToken.mint(bagelToken.owner(), AMOUNT_TO_TRANSFER);
        IERC20(bagelToken).transfer(address(merkleAirdrop), AMOUNT_TO_TRANSFER);
        vm.stopBroadcast();
        return (bagelToken, merkleAirdrop);
    }
}
