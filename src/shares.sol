// contracts/Share.sol
// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Share is ERC20 {

    // State variables for name and symbol
    string private _name;
    string private _symbol;

    constructor(uint256 initialSupply) ERC20("someShare", "SS") {
        _name = "someShare";
        _symbol = "SS";
        _mint(msg.sender, initialSupply);
  
    }

function mint()public{}
    // Override the name function to use the custom _name variable
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    // Override the symbol function to use the custom _symbol variable
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    // Set the token name, only callable by an admin
    function setName(string memory newName) public{
        _name = newName;
    }

    // Set the token symbol, only callable by an admin
    function setSymbol(string memory newSymbol) public  {
        _symbol = newSymbol;
    }

    // Allows addresses with ISSUER_ROLE to mint tokens
    function mint(address to, uint256 amount) public  {
        _mint(to, amount);
    }

    // Enable transfer of tokens, overriding ERC20 function to add custom logic if needed
    function transfer(address recipient, uint256 amount) public virtual override returns (bool) {
        require(balanceOf(_msgSender()) >= amount, "ERC20: transfer amount exceeds balance");
        _transfer(_msgSender(), recipient, amount);
        return true;
    }


    
}
