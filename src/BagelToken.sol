// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";




/**
 * @title BagelToken
 * @author Okhamena Azeez
 * @notice This contract implements a basic ERC20 token with minting capabilities
 * @dev Extends OpenZeppelin's ERC20 and Ownable contracts */
contract BagelToken is ERC20, Ownable {
    /**
     * @notice Contract constructor that initializes the token with name "BagelToken" and symbol "BGL"
     */
     
    constructor() ERC20("BagelToken", "BGL") Ownable(msg.sender) {}

    /**
     * @notice Allows the owner to mint new tokens
     * @dev Only callable by the contract owner
     * @param to The address that will receive the minted tokens
     * @param amount The amount of tokens to mint
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}
