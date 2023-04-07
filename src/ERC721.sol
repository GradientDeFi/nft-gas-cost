// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TokenERC721 is ERC721 {
    constructor() ERC721("Token", "TKN") {}

    uint16 public maxSupply = 10000;
    uint16 public supply = 0;

    function mint() external payable {
        require(supply < maxSupply);
        _mint(msg.sender, supply);
        supply += 1;
    }
}
