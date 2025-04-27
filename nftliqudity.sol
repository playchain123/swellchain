// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IERC721 {
    function transferFrom(address from, address to, uint256 tokenId) external;
}

contract NFTLiquidityPool {
    address public owner;
    IERC20 public metaPlayXToken;
    
    struct NFTInfo {
        address nftAddress;
        uint256 tokenId;
        uint256 price;
        bool isListed;
    }

    NFTInfo[] public nftsInPool;

    event NFTDeposited(address indexed depositor, address indexed nftAddress, uint256 tokenId, uint256 price);
    event NFTPurchased(address indexed buyer, address indexed nftAddress, uint256 tokenId, uint256 price);
    
    constructor(address _metaPlayXToken) {
        owner = msg.sender;
        metaPlayXToken = IERC20(_metaPlayXToken);
    }

    function depositNFT(address _nftAddress, uint256 _tokenId, uint256 _price) external {
        require(_price > 0, "Price must be greater than 0");
        
        IERC721(_nftAddress).transferFrom(msg.sender, address(this), _tokenId);
        
        nftsInPool.push(NFTInfo({
            nftAddress: _nftAddress,
            tokenId: _tokenId,
            price: _price,
            isListed: true
        }));

        emit NFTDeposited(msg.sender, _nftAddress, _tokenId, _price);
    }

    function buyNFT(uint256 _nftIndex) external {
        require(_nftIndex < nftsInPool.length, "Invalid NFT index");
        NFTInfo storage nft = nftsInPool[_nftIndex];
        require(nft.isListed, "NFT already sold");

        // Transfer MetaPlayX tokens from buyer to pool
        require(metaPlayXToken.transferFrom(msg.sender, address(this), nft.price), "MetaPlayX token transfer failed");
        
        // Transfer NFT from pool to buyer
        IERC721(nft.nftAddress).transferFrom(address(this), msg.sender, nft.tokenId);
        
        nft.isListed = false;

        emit NFTPurchased(msg.sender, nft.nftAddress, nft.tokenId, nft.price);
    }

    function withdrawTokens(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can withdraw");
        require(metaPlayXToken.transfer(owner, _amount), "Token transfer failed");
    }

    function getPoolSize() external view returns (uint256) {
        return nftsInPool.length;
    }

    function getNFTInfo(uint256 _index) external view returns (address, uint256, uint256, bool) {
        NFTInfo memory nft = nftsInPool[_index];
        return (nft.nftAddress, nft.tokenId, nft.price, nft.isListed);
    }
}
