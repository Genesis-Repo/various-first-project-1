// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";

contract NFTMarketplace is ERC721Enumerable {
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    address public owner;
    uint256 public royaltyFee; // Royalty fee in percentage
    uint256 public secondarySaleFee; // Fee on secondary sales in percentage

    mapping(uint256 => uint256) private _tokenRoyalties; // Royalty fee for each token
    mapping(uint256 => address) private _tokenCreators; // Creator of each token
    EnumerableMap.UintToAddressMap private _tokenRoyaltyRecipients; // Royalty recipients for each token

    event RoyaltySet(uint256 indexed tokenId, uint256 royaltyFee, address royaltyRecipient);
    event NFTSold(address buyer, uint256 tokenId, uint256 price);

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) {
        owner = _msgSender();
        royaltyFee = 5; // 5% royalty fee by default
        secondarySaleFee = 2; // 2% fee on secondary sales by default
    }

    function setRoyalty(uint256 tokenId, uint256 royaltyFee, address royaltyRecipient) public {
        require(_exists(tokenId), "Token does not exist");
        require(_isApprovedOrOwner(_msgSender(), tokenId), "Caller is not owner nor approved");

        _tokenRoyalties[tokenId] = royaltyFee;
        _tokenRoyaltyRecipients.set(tokenId, royaltyRecipient);

        emit RoyaltySet(tokenId, royaltyFee, royaltyRecipient);
    }

    function buyNFT(uint256 tokenId) public payable {
        require(_exists(tokenId), "Token does not exist");
        address tokenOwner = ownerOf(tokenId);
        require(tokenOwner != address(0), "Invalid token owner");

        uint256 price = msg.value;
        uint256 tokenRoyalty = (price * _tokenRoyalties[tokenId]) / 100;
        uint256 amountAfterRoyalty = price - tokenRoyalty;

        payable(tokenOwner).transfer(amountAfterRoyalty); // Send payment to token owner

        // Apply secondary sale fee
        uint256 secondarySaleAmount = (price * secondarySaleFee) / 100;
        payable(owner).transfer(secondarySaleAmount); // Send secondary sale fee to contract owner
        
        uint256 amountToSeller = amountAfterRoyalty - secondarySaleAmount;
        payable(_tokenRoyaltyRecipients.get(tokenId)).transfer(tokenRoyalty); // Send royalty fee to recipient

        _transfer(tokenOwner, _msgSender(), tokenId); // Transfer ownership of token

        emit NFTSold(_msgSender(), tokenId, price);
    }

    function setRoyaltyFee(uint256 newRoyaltyFee) public {
        require(_msgSender() == owner, "Caller is not the owner");
        royaltyFee = newRoyaltyFee;
    }

    function setSecondarySaleFee(uint256 newSecondarySaleFee) public {
        require(_msgSender() == owner, "Caller is not the owner");
        secondarySaleFee = newSecondarySaleFee;
    }
}