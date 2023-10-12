
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract SponsorshipToken is ERC20, Ownable {

    mapping(address => bool) minted;

    constructor(string memory name, string memory symbol, uint256 initialSupply) ERC20(name, symbol) {
        _mint(address(this), initialSupply * (10 ** decimals()));
    }

    function mintToken() public {
        require(minted[msg.sender] == false, "Already minted");
        uint bal = balanceOf(address(this));
        uint amount = 10 *1e18;
        require(bal >= amount, "You are transferring more than the amount available!");
        minted[msg.sender] = true;
        _transfer(address(this), msg.sender, amount);
    }

}
