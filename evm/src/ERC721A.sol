// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "erc721a/contracts/ERC721A.sol";

contract TokenERC721A is ERC721A {
    constructor() ERC721A("Token", "TKN") {}

    uint16 public maxSupply = 10000;

    function mint() external payable {
        uint256 supply = totalSupply();
        require(supply < maxSupply);
        // `_mint`'s second argument now takes in a `quantity`, not a `tokenId`.
        _mint(msg.sender, 1);
    }
}