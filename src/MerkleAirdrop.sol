//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

/**
 * @title MerkleAirdrop
 * @author Okhamena Azeez
 * @notice This contract allows for a Merkle tree-based airdrop of ERC20 tokens.
 * Users can claim tokens if their address and amount are included in the Merkle tree
 * and they provide a valid Merkle proof along with a valid EIP-712 signature.
 * @dev This contract implements EIP-712 for signature verification and uses Merkle proofs
 * for efficient whitelist verification without storing all addresses on-chain.
 */
contract MerkleAirDrop is EIP712  {
    using SafeERC20 for IERC20;

    /* ========== CONSTANTS ========== */

    /**
     * @notice The EIP-712 type hash for the AirdropClaim struct
     * @dev This is used for signature verification
     */
    bytes32 private constant MESSAGE_TYPEHASH = keccak256("AirdropClaim(address claimer,uint256 amount)");

    /* ========== STRUCTS ========== */

    /**
     * @notice Struct representing an airdrop claim
     * @param claimer The address of the user claiming tokens
     * @param amount The amount of tokens to be claimed
     */
    struct AirdropClaim {
        address claimer;
        uint256 amount;
    }

    struct ClaimParams {
    address claimer;
    uint256 amount;
    bytes32[] merkleProof;
    uint8 v;
    bytes32 r;
    bytes32 s;
}

    /* ========== ERRORS ========== */

    /**
     * @notice Thrown when the provided Merkle proof is invalid
     * @dev This error is raised when the Merkle proof doesn't verify against the stored root
     */
    error MerkleAirdrop__InvalidProof();

    /**
     * @notice Thrown when an address tries to claim tokens more than once
     * @dev This prevents double-spending of airdrop tokens
     */
    error MerkleAirdrop__AlreadyClaimed();

    /**
     * @notice Thrown when the provided EIP-712 signature is invalid
     * @dev This error is raised when the signature doesn't match the expected signer
     */
    error MerkleAirdrop__InvalidSignature();

    /* ========== EVENTS ========== */

    /**
     * @notice Emitted when a user successfully claims their tokens
     * @param claimer The address that claimed the tokens
     * @param amount The amount of tokens claimed
     */
    event Claimed(address indexed claimer, uint256 amount);

    /* ========== STATE VARIABLES ========== */

    /**
     * @notice The Merkle root of the airdrop whitelist
     * @dev This is set during construction and cannot be changed
     */
    bytes32 private immutable i_merkleRoot;

    /**
     * @notice The ERC20 token being airdropped
     * @dev This is set during construction and cannot be changed
     */
    IERC20 public immutable i_airDropToken;

    /**
     * @notice Mapping to track which addresses have already claimed their tokens
     * @dev Prevents double-claiming of airdrop tokens
     */
    mapping(address claimer => bool claimed) private s_claimed;

    /* ========== CONSTRUCTOR ========== */

    /**
     * @notice Constructs the MerkleAirdrop contract
     * @param _merkleRoot The Merkle root for the airdrop whitelist
     * @param airDropToken The address of the ERC20 token to be airdropped
     * @dev The contract name is set to "MerkleAirdrop" for EIP-712 domain separation
     */
    constructor(bytes32 _merkleRoot, IERC20 airDropToken) EIP712("MerkleAirdrop", "1") {
        i_merkleRoot = _merkleRoot;
        i_airDropToken = airDropToken;
    }

    /* ========== MODIFIERS ========== */

    /**
     * @notice Checks if the given address has not already claimed the airdrop
     * @param _claimer The address attempting to claim
     * @dev Reverts with MerkleAirdrop__AlreadyClaimed if the address has already claimed
     */
    modifier onlyUnclaimed(address _claimer) {
        if (s_claimed[_claimer] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        _;
    }

    /**
     * @notice Checks that the provided EIP-712 signature is valid for the given claimer and message hash
     * @param _claimer The address of the claimer (expected signer)
     * @param _amount The amount of tokens being claimed
     * @param v The v component of the signature
     * @param r The r component of the signature
     * @param s The s component of the signature
     * @dev Reverts with MerkleAirdrop__InvalidSignature if the signature is invalid
     */
    modifier validSignature(address _claimer, uint256 _amount, uint8 v, bytes32 r, bytes32 s) {
        if (!_isValidSignature(_claimer, getMessageHash(_claimer, _amount), v, r, s)) {
            revert MerkleAirdrop__InvalidSignature();
        }
        _;
    }

    /**
     * @notice Checks that the provided Merkle proof is valid for the given claimer and amount
     * @param _claimer The address attempting to claim
     * @param _amount The amount of tokens being claimed
     * @param _merkleProof The Merkle proof to verify inclusion in the airdrop
     * @dev Reverts with MerkleAirdrop__InvalidProof if the proof is invalid
     */
    modifier validMerkleProof(address _claimer, uint256 _amount, bytes32[] calldata _merkleProof) {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(_claimer, _amount))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        _;
    }

    /* ========== EXTERNAL FUNCTIONS ========== */

    /**
     * @notice Allows a whitelisted user to claim their airdropped tokens
     * @param _claimParams The parameters for the claim:
     * @custom:param claimer The address attempting to claim
     * @custom:param amount The amount of tokens to claim
     * @custom:param merkleProof The Merkle proof required to verify the claimer's inclusion in the whitelist
     * @custom:param v The v component of the EIP-712 signature
     * @custom:param r The r component of the EIP-712 signature
     * @custom:param s The s component of the EIP-712 signature
     * @dev This function performs the following checks:
     * 1. Verifies the address hasn't already claimed
     * 2. Validates the EIP-712 signature
     * 3. Verifies the Merkle proof
     * 4. Transfers tokens to the claimer
     */
    function claim(
        ClaimParams calldata _claimParams
    )
        external
        onlyUnclaimed(_claimParams.claimer)
        validSignature(_claimParams.claimer, _claimParams.amount, _claimParams.v, _claimParams.r, _claimParams.s)
        validMerkleProof(_claimParams.claimer, _claimParams.amount, _claimParams.merkleProof)
    {
        s_claimed[_claimParams.claimer] = true;
        emit Claimed(_claimParams.claimer, _claimParams.amount);
        i_airDropToken.safeTransfer(_claimParams.claimer, _claimParams.amount);
    }

    /* ========== PUBLIC FUNCTIONS ========== */

    /**
     * @notice Generates the EIP-712 message hash for signature verification
     * @param _claimer The address of the claimer
     * @param _amount The amount of tokens to be claimed
     * @return The EIP-712 message hash
     * @dev This function creates the message hash that should be signed by the authorized signer
     */
    function getMessageHash(address _claimer, uint256 _amount) public view returns (bytes32) {
        return _hashTypedDataV4(
            keccak256(abi.encode(MESSAGE_TYPEHASH, AirdropClaim({claimer: _claimer, amount: _amount})))
        );
    }

    /* ========== EXTERNAL VIEW FUNCTIONS ========== */

    /**
     * @notice Returns the Merkle root of the airdrop
     * @return The Merkle root
     */
    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    /**
     * @notice Returns the address of the airdrop token
     * @return The ERC20 token contract address
     */
    function getAirDropToken() external view returns (IERC20) {
        return i_airDropToken;
    }

    /**
     * @notice Checks if an address has already claimed their airdrop
     * @param _claimer The address to check
     * @return True if the address has already claimed, false otherwise
     */
    function hasClaimed(address _claimer) external view returns (bool) {
        return s_claimed[_claimer];
    }

    /* ========== INTERNAL FUNCTIONS ========== */

    /**
     * @notice Validates an EIP-712 signature
     * @param _claimer The address of the claimer
     * @param _digest The digest to verify
     * @param v The v component of the signature
     * @param r The r component of the signature
     * @param s The s component of the signature
     * @return True if the signature is valid, false otherwise
     * @dev This function should be overridden to implement the actual signature verification logic
     */
    function _isValidSignature(address _claimer, bytes32 _digest, uint8 v, bytes32 r, bytes32 s)
        internal
        pure
        returns (bool)
    {
        (address actualSigner,,)=ECDSA.tryRecover(_digest,v,r,s);
        return actualSigner == _claimer;
    }
}
