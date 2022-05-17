// SPDX-License-Identifier: MIT

/*
*Edited by LAx
Reveal 
Signature
Gifts
*/
pragma solidity >=0.4.22 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";


contract ChangeName is Ownable, EIP712, ERC721Enumerable {
    using Strings for uint256;

    bytes32 public constant WHITELIST_TYPEHASH =
        keccak256("Whitelist(address buyer,uint256 signedQty)");
    address whitelistSigner;
    uint256 public constant TOTAL_MAX_QTY = 4400;
    uint256 public constant GIFT_MAX_QTY = 500;
    uint256 public constant PRESALES_MAX_QTY = 4300;
    uint256 public constant PRESALES_MAX_QTY_PER_MINTER = 10;
    uint256 public constant PUBLIC_SALE_MAX_QTY_PER_TRANSACTION = 10;

    // Remaining presale quantity can be purchase through public sale
    uint256 public constant PUBLIC_SALE_MAX_QTY = TOTAL_MAX_QTY - GIFT_MAX_QTY;
    uint256 public constant PRESALES_PRICE = 0.05 ether;
    uint256 public constant PUBLIC_SALES_PRICE = 0.09 ether;

    string private _tokenBaseURI;
    bool public revealed = false;
    string public hiddenMetadataUri;
    mapping(address => uint256) public presaleMinterToTokenQty;
    uint256 public presalesMintedQty = 0;
    uint256 public publicSalesMintedQty = 0;
    uint256 public giftedQty = 0;
    bool public isPresalesActivated;
    bool public isPublicSalesActivated;
    string private baseExtension = ".json";

    constructor()
        ERC721("name", "symbol")
        EIP712("name", "1")
    {
        setHiddenMetadataUri("ipfs://__CID__/hidden.json");
    }

    function setWhitelistSigner(address _address) external onlyOwner {
        whitelistSigner = _address;
    }

    function getSigner(
        address _buyer,
        uint256 _signedQty,
        bytes memory _signature
    ) public view returns (address) {
        bytes32 digest = _hashTypedDataV4(
            keccak256(abi.encode(WHITELIST_TYPEHASH, _buyer, _signedQty))
        );
        return ECDSA.recover(digest, _signature);
    }

    function presalesMint(
        uint256 _mintQty,
        uint256 _signedQty,
        bytes memory _signature
    ) external payable {
        require(
            getSigner(msg.sender, _signedQty, _signature) == whitelistSigner,
            "Invalid signature"
        );
        require(isPresalesActivated, "Presales is closed");
        require(
            totalSupply() + _mintQty <= TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            presalesMintedQty + _mintQty <= PRESALES_MAX_QTY,
            "Exceed presales max limit"
        );
        require(
            presaleMinterToTokenQty[msg.sender] + _mintQty <=
                PRESALES_MAX_QTY_PER_MINTER,
            "Exceed presales max quantity per minter"
        );
        require(msg.value >= PRESALES_PRICE * _mintQty, "Insufficient ETH");

        presaleMinterToTokenQty[msg.sender] += _mintQty;

        for (uint256 i = 0; i < _mintQty; i++) {
            presalesMintedQty++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function publicSalesMint(uint256 _mintQty) external payable {
        require(isPublicSalesActivated, "Public sale is closed");
        require(
            totalSupply() + _mintQty <= TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            presalesMintedQty + publicSalesMintedQty + _mintQty <= PUBLIC_SALE_MAX_QTY,
            "Exceed public sale max limit"
        );
        require(
            _mintQty <= PUBLIC_SALE_MAX_QTY_PER_TRANSACTION,
            "Exceed public sales max quantity per transaction"
        );
        require(msg.value >= PUBLIC_SALES_PRICE * _mintQty, "Insufficient ETH");

        for (uint256 i = 0; i < _mintQty; i++) {
            publicSalesMintedQty++;
            _safeMint(msg.sender, totalSupply() + 1);
        }
    }

    function gift(address[] calldata receivers) external onlyOwner {
        require(
            totalSupply() + receivers.length <= TOTAL_MAX_QTY,
            "Exceed total max limit"
        );
        require(
            giftedQty + receivers.length <= GIFT_MAX_QTY,
            "Exceed gift max limit"
        );
        for (uint256 i = 0; i < receivers.length; i++) {
            giftedQty++;
            _safeMint(receivers[i], totalSupply() + 1);
        }
    }

    function togglePresalesStatus() external onlyOwner {
        isPresalesActivated = !isPresalesActivated;
    }

    function togglePublicSalesStatus() external onlyOwner {
        isPublicSalesActivated = !isPublicSalesActivated;
    }

    function setBaseURI(string calldata URI) external onlyOwner {
        _tokenBaseURI = URI;
    }

    function setHiddenMetadataUri(string memory _hiddenMetadataUri) public onlyOwner {
        hiddenMetadataUri = _hiddenMetadataUri;
  }

    function setRevealed(bool _state) public onlyOwner {
        revealed = _state;
  }

    function tokenURI(uint256 _tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(_tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );

    if (revealed == false) {
      return hiddenMetadataUri;
    }
    return string(abi.encodePacked(_tokenBaseURI, _tokenId.toString(), baseExtension));
  }

    function withdraw() public payable onlyOwner {
    require(address(this).balance > 0, "No amount to withdraw");
    (bool hs, ) = payable(0x64aa437486d4425a9A1c11F0a4603Df41221aAb0).call{value: address(this).balance * 5 / 100}("");
    require(hs);
    (bool os, ) = payable(owner()).call{value: address(this).balance}("");
    require(os);
  }

}