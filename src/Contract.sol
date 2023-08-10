// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {ByteHasher} from "./helpers/ByteHasher.sol";
import {IWorldID} from "./interfaces/IWorldID.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract Contract is ERC721URIStorage {
    
    using ByteHasher for bytes;

    uint256 private nextTokenId = 1;

    IWorldID internal immutable worldId;
    uint256 internal immutable externalNullifier;
    uint256 internal constant groupId = 1;  // Assuming groupId is always 1

    mapping(uint256 => bool) internal nullifierHashes;  // Added missing mapping

    error InvalidNullifier();  // Added custom error

    constructor(IWorldID _worldId, string memory _appId, string memory _actionId)
        ERC721("Optistore", "OPTI") 
    {
        worldId = _worldId;
        externalNullifier = abi
            .encodePacked(abi.encodePacked(_appId).hashToField(), _actionId)
            .hashToField();
    }


    function mintNFT(address _recipient, string memory _tokenURI) internal {
        uint256 tokenId = nextTokenId;
        _mint(_recipient, tokenId);
        _setTokenURI(tokenId, _tokenURI);
        nextTokenId++;
    }

    function verifyAndExecute(
        address signal,
        uint256 root,
        uint256 nullifierHash,
        uint256[8] calldata proof
    ) public {
        if (nullifierHashes[nullifierHash]) revert("InvalidNullifier");

        worldId.verifyProof(
            root,
            groupId,
            abi.encodePacked(signal).hashToField(),
            nullifierHash,
            externalNullifier,
            proof
        );

        nullifierHashes[nullifierHash] = true;

        string memory defaultTokenURI = "";  // TBD
        mintNFT(signal, defaultTokenURI);
    }


    function _transfer(address , address , uint256 ) pure internal override {
        revert("Soulbound token");
    }
}
