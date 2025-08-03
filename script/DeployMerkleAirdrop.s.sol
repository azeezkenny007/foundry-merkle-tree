//SPDX-License-Identifier:MIT
pragma solidity ^0.8.24;

import {MerkleAirDrop,IERC20} from "../src/MerkleAirDrop.sol"; // Fixed case in file name
import {Script} from "forge-std/Script.sol";
import {BagelToken} from "../src/BagelToken.sol";
import {ZkSyncChainChecker} from "lib/foundry-devops/src/ZkSyncChainChecker.sol";

/**
 * @title DeployMerkleAirDrop
 * @author Okhamena Azeez
 * @notice This contract deploys both BagelToken and MerkleAirDrop contracts for an airdrop campaign
 * @dev A Foundry script that handles the complete deployment and initial setup of the airdrop system.
 *      It creates the ERC20 token, deploys the merkle airdrop contract, and funds it with tokens.
 */
contract DeployMerkleAirDrop is Script {
    /**
     * @notice The merkle root hash for validating airdrop claims
     * @dev This root is calculated from all eligible addresses and their claim amounts
     
     */
    bytes32 public MERKLE_ROOT = bytes32(0xaa5d581231e596618465a56aa0f5870ba6e20785fe436d5bfb82b08662ccc7c4);
    
    /**
     * @notice The total amount of tokens to transfer to the airdrop contract
     * @dev Calculated as 4 users * 25 tokens * 1e18 (18 decimals)
     */
    uint256 public constant AMOUNT_TO_TRANSFER = 4 * 25 * 1e18;
    

    /**
     * @notice Deploys and initializes the complete airdrop system
     * @dev This function performs the following steps:
     *      1. Deploys a new BagelToken contract
     *      2. Deploys a MerkleAirDrop contract with the predefined merkle root
     *      3. Mints tokens to the BagelToken owner
     *      4. Transfers the required amount to the airdrop contract for distribution
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
