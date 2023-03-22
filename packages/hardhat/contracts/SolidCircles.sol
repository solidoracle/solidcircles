//SPDX-License-Identifier: CC0
pragma solidity ^0.8.12;

// Title: SolidCircles
// Author: @solidoracle
// ┌─┐┌─┐┬  ┬┌┬┐┌─┐┬┬─┐┌─┐┬  ┌─┐┌─┐
// └─┐│ ││  │ │││  │├┬┘│  │  ├┤ └─┐
// └─┘└─┘┴─┘┴─┴┘└─┘┴┴└─└─┘┴─┘└─┘└─┘

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./Utils.sol";
import "./ArtGeneratorInterface.sol";
import "@openzeppelin/contracts/utils/Counters.sol";


contract SolidCircles is ERC721Enumerable, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    uint256 public constant MAX_SOLIDCIRCLES = 777;
    uint256 public PRICE;
    uint256 private _currentIndex;

    mapping(uint256 => uint256) public seeds;
    mapping(address => uint256) public mintedAddress;

    ArtGeneratorInterface public artGenerator;
    constructor(ArtGeneratorInterface _artGenerator)
        ERC721("SolidCircles", "SC")
    {
        artGenerator = _artGenerator;
        _currentIndex = 0;
        PRICE = 0.001 ether;
    }

    event onMintSuccess(address sender, uint256 tokenId);

    function _createSeed(uint256 _tokenId, address _address)
        internal
        view
        returns (uint256)
    {
        return
            uint256(
                keccak256(
                    abi.encodePacked(
                        _tokenId,
                        _address,
                        utils.getRandomInteger("solidcircles", _tokenId, 0, 42069),
                        block.difficulty,
                        block.timestamp
                    )
                )
            );
    }

    function tokenURI(uint256 _tokenId)
        public
        view
        override
        returns (string memory)
    {
        return artGenerator.tokenURI(_tokenId, seeds[_tokenId]);
    }


    function mintItem() external payable nonReentrant returns(uint256)  {
        require(PRICE <= msg.value, "Not enough eth sent to mint a SolidCircle");
        require(_currentIndex <= MAX_SOLIDCIRCLES, "All SolidCircles minted");
        require(
            _currentIndex + 1 <= MAX_SOLIDCIRCLES,
            "Minting exceeds max supply"
        );

        _tokenIds.increment();

        uint256 id = _tokenIds.current();
        _mint(msg.sender, id);
        mintedAddress[msg.sender] += 1;
        _currentIndex++;
        seeds[id] = _createSeed(id, msg.sender);

        payable(0x0FeBf44BA535AB608b5f25509E9eb0Ed590a896C).transfer(msg.value);

        PRICE += 0.001 ether;

        emit onMintSuccess(msg.sender, id);

        return id;
    }


    function withdraw() external payable onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function setGenerator(ArtGeneratorInterface _artGenerator)
        external
        onlyOwner
    {
        artGenerator = _artGenerator;
    }

    function setPrice(uint256 _price) external onlyOwner {
        PRICE = _price;
    }

}
