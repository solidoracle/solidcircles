//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.12;

interface ArtGeneratorInterface {
    function tokenURI(uint256 _tokenId, uint256 _seed)
        external
        view
        returns (string memory);
}
