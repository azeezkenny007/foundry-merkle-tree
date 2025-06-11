//SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20, SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirDrop {
    using SafeERC20 for IERC20;
    error MerkleAirdrop__InvalidProof();
    error MerkleAirdrop__AlreadyClaimed();

    event Claimed(address indexed claimer, uint256 amount);

    bytes32 private immutable i_merkleRoot;
    address[] public claimers;
    IERC20 public immutable i_airDropToken;
    mapping(address claimer => bool claimed) private s_claimed;

    constructor(bytes32 _merkleRoot, IERC20 airDropToken) {
        i_merkleRoot = _merkleRoot;
        i_airDropToken = airDropToken;
    }
    

    function claim(address _claimer, uint256 _amount, bytes32[] calldata _merkleProof) external {
        if (s_claimed[_claimer] == true) {
            revert MerkleAirdrop__AlreadyClaimed();
        }
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encodePacked(_claimer, _amount))));
        if (!MerkleProof.verify(_merkleProof, i_merkleRoot, leaf)) {
            revert MerkleAirdrop__InvalidProof();
        }
        s_claimed[_claimer] = true;
        emit Claimed(_claimer, _amount);
        i_airDropToken.safeTransfer(_claimer, _amount);
    }

    function getMerkleRoot() external view returns (bytes32) {
        return i_merkleRoot;
    }

    function getAirDropToken() external view returns (IERC20) {
        return i_airDropToken;
    }
}
