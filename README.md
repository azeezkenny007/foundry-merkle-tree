# Foundry Merkle Tree Project: Detailed Documentation

This project provides a robust and efficient solution for implementing Merkle Trees and a token airdrop mechanism on the Ethereum blockchain, leveraging the powerful Foundry development toolkit. It's designed for developers looking to understand and deploy secure, verifiable token distribution systems.

## 1. Project Overview & Architecture

This repository is structured to clearly separate concerns: smart contracts, deployment/utility scripts, and testing. The core idea revolves around using a Merkle tree to efficiently verify a large set of eligible addresses for a token airdrop without storing all addresses on-chain.

### 1.1 Core Components:

-   **`src/BagelToken.sol`**: This is a standard ERC20 token contract, serving as the token to be distributed via the airdrop. It's built upon OpenZeppelin's battle-tested `ERC20` and `Ownable` contracts, ensuring security and adherence to standards. The owner has the sole privilege to mint new tokens, providing controlled supply management.
    -   **Key Features**: ERC20 compliance, `Ownable` access control, `mint` function for token creation.
    -   **Usage**: The `MerkleAirdrop` contract will hold and distribute instances of this token.

-   **`src/MerkleAirdrop.sol`**: The central contract for the airdrop mechanism. It stores a single Merkle root, which is a cryptographic hash representing the entire set of eligible recipients and their respective token amounts. Users can claim tokens by providing a valid Merkle proof, which is verified against this root.
    -   **Key Features**: 
        -   `i_merkleRoot`: An immutable variable storing the Merkle root, set during construction.
        -   `i_airDropToken`: An immutable reference to the ERC20 token contract being distributed.
        -   `s_claimed`: A mapping to prevent double-claiming by tracking addresses that have already successfully claimed.
        -   `claim(address _claimer, uint256 _amount, bytes32[] calldata _merkleProof)`: The primary function allowing eligible users to claim tokens. It verifies the provided `_merkleProof` against the `i_merkleRoot` and the `_claimer`'s address and `_amount`. If valid and not already claimed, it transfers the tokens and marks the address as claimed.
        -   **Error Handling**: Includes custom errors `MerkleAirdrop__InvalidProof()` and `MerkleAirdrop__AlreadyClaimed()` for clear feedback.
        -   **Events**: Emits a `Claimed` event upon successful token distribution.
    -   **Interaction Flow**: Users generate their unique Merkle proof off-chain (using scripts provided) and then submit it to this contract to claim their allocation.

-   **`script/GenerateInput.s.sol`**: A Foundry script designed to prepare the raw data for Merkle tree generation. It defines a hardcoded list of addresses and a fixed amount for each, then formats this data into a `input.json` file. This file serves as the structured input for the Merkle tree construction process.
    -   **Purpose**: Automates the creation of the initial whitelist data in a machine-readable format.
    -   **Output**: `script/target/input.json`

-   **`script/MakeMerkle.s.sol`**: (Inferred Functionality) This script is crucial for the cryptographic heavy lifting. It reads the `input.json` file, constructs the Merkle tree, calculates the Merkle root, and generates individual Merkle proofs for each entry. The output, typically `output.json`, would contain the Merkle root and all necessary proofs for on-chain verification.
    -   **Purpose**: Transforms raw whitelist data into a verifiable Merkle tree structure.
    -   **Output**: `script/target/output.json` (containing Merkle root and proofs).

## 2. Getting Started

To set up and run this project, follow these steps:

### 2.1 Prerequisites

Ensure you have the Foundry development toolkit installed. If not, you can install it by running:

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```
