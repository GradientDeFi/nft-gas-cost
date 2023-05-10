// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;

import "forge-std/Test.sol";

import "../src/ERC721.sol";
import "../src/ERC721A.sol";
import "../src/ERC721Enumerable.sol";

contract GasTest is Test {
    TokenERC721 public t721;
		TokenERC721A public t721a;
		TokenERC721Enumerable public t721e;

    function setUp() public {
        t721 = new TokenERC721();
				t721a = new TokenERC721A();
				t721e = new TokenERC721Enumerable();
		}

		function testMintOnce() public {
				t721.mint();
				t721a.mint();
				t721e.mint();
		}

		function testMint10k() public {
				for (uint i = 0; i < 10000; i++) {
					t721.mint();
					t721a.mint();
					t721e.mint();
				}
		}

		function testMint10kGasDeal() public {
			vm.deal(address(this), 10000000 ether);
			testMint10k();
		}
}
