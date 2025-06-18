//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @title MerkleAirdrop
 * @author Okhamena Azeez
 * @notice This contract allows for a Merkle tree-based airdrop of ERC20 tokens.
 * Users can claim tokens if their address and amount are included in the Merkle tree
 * and they provide a valid Merkle proof.
 */
contract MerkleAirDrop {
    using SafeERC20 for IERC20;
    /// @custom:error Thrown when the provided Merkle proof is invalid.

    error MerkleAirdrop__InvalidProof();

    /// @custom:error Thrown when an address tries to claim tokens more than once.
    error MerkleAirdrop__AlreadyClaimed();

    error MerkleAirdrop__InvalidSignature()

     struct AirdropClaim{
        address claimer;
        uint256 amount;
     }  

    /**
     * @notice Emitted when a user successfully claims their tokens.
     * @param claimer The address that claimed the tokens.
     * @param amount The amount of tokens claimed.
     */
    event Claimed(address indexed claimer, uint256 amount);

    /// @notice The Merkle root of the airdrop whitelist.
    bytes32 private immutable i_merkleRoot;
    /// @notice The ERC20 token being airdropped.
    IERC20 public immutable i_airDropToken;
    /// @notice Mapping to track which addresses have already claimed their tokens.
    mapping(address claimer => bool claimed) private s_claimed;

    /**
     * @notice Constructs the MerkleAirdrop contract.
     * @param _merkleRoot The Merkle root for the airdrop whitelist.
     * @param airDropToken The address of the ERC20 token to be airdropped.
     */
    constructor(bytes32 _merkleRoot, IERC20 airDropToken) {
        i_merkleRoot = _merkleRoot;
        i_airDropToken = airDropToken;
    }

    /**
     * @notice Allows a whitelisted user to claim their airdropped tokens.
     * @param _claimer The address attempting to claim.
     * @param _amount The amount of tokens to claim.
     * @param _merkleProof The Merkle proof required to verify the claimer's inclusion in the whitelist.
     */
    function claim(address _claimer, uint256 _amount, bytes32[] calldata _merkleProof,uint8 v, bytes32 r, bytes32 s) external {
        if (s_claimed[_claimer] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }

        if(!_IsValidSignature(_claimer,getMessage(_claimer,amount),v,r,s)){
            revert MerkleAirdrop__InvalidSignature();
        }

        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_claimer, _amount))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_claimed[_claimer] = true;
        emit Claimed(_claimer, _amount);
        i_airDropToken.safeTransfer(_claimer, _amount);
    }

    /**
     * @notice Returns the Merkle root of the airdrop.
     * @return The Merkle root.
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getMessage(address _claimer,uint256 _amount) public view returns(bytes32){
        return  _hashTypedDataV4(keccak256(abi.encode(keccak256(abi.encode(MESSAGE_TYPEHASH, _claimer, _amount)))));
    }

    /**
     * @notice Returns the address of the airdrop token.
     * @return The ERC20 token contract.
     */
    function getAirDropToken() external view returns (IERC20) {
        return i_airDropToken;
    }
}
