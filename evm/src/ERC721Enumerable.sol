// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract TokenERC721Enumerable is ERC721Enumerable {
		constructor() ERC721("Token", "TKN") {}

		uint16 public maxSupply = 10000;

		function mint() external payable {
				uint256 supply = totalSupply();
        require(supply < maxSupply);
        _mint(msg.sender, supply);
    }
}