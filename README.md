// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IPass {
    function ownerOf(uint256 tokenId) external returns (address);
    function balanceOf(address owner) external view returns (uint256);
    function burn(uint256 _tokenId) external;
    function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);

}

contract Dwarf is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
   
    uint256 public constant MAX_SUPPLY = 9999; //  MAX_SUPPLY - My mintPass = number of siblings of my mintPass
    uint256 private constant MINT_PRICE = 0.01 ether;
    bytes32 public root; // who can mint?
    string BASE_URI; // What will my mintPass look like?

    bool public IS_OG_SALE_ACTIVE = false; // can we mint?
    bool public IS_PRE_SALE_ACTIVE = false; // can we mint?
    bool public IS_PUBLIC_SALE_ACTIVE = false; // can we mint?
    uint256 constant NUMBER_OF_TOKENS_ALLOWED_PER_OG = 1; // How many can I mint from this mintPass?
    uint256 constant NUMBER_OF_TOKENS_ALLOWED_PER_PRE = 1;
    uint256 constant NUMBER_OF_TOKENS_ALLOWED_PER_PUBLIC = 1;
    uint256 constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 10;

    mapping (address => uint256) addressToMintCount; // how many mint passes do i have

    IPass ipass;

    /*
    @Person: Will bots be able to mint?

    @return: No. 
    */
    modifier onlyAccounts () {
        require(msg.sender == tx.origin, "Not allowed origin");
        _;
    }
    

    constructor(string memory name, string memory symbol, string memory _BASE_URI)
    ERC721(name, symbol)
    {
        BASE_URI = _BASE_URI;
        // root = merkleroot;
        _tokenIdCounter.increment();
    }

    function setPassContractAddress(address _contractAddress) public onlyOwner{
        ipass = IPass(_contractAddress);
    }

    function setMerkleRoot(bytes32 merkleroot) 
    onlyOwner 
    public 
    {
        root = merkleroot;
    }

    function _baseURI() internal view override returns (string memory) {
        return BASE_URI;
    }
    
    function setBaseURI(string memory newUri) 
    public 
    onlyOwner {
        BASE_URI = newUri;
    }

    function toggleOGSale() public 
    onlyOwner 
    {
        IS_OG_SALE_ACTIVE = !IS_OG_SALE_ACTIVE;
    }

    function togglePreSale() public 
    onlyOwner 
    {
        IS_PRE_SALE_ACTIVE = !IS_PRE_SALE_ACTIVE;
    }
    
    
    function togglePublicSale() public 
    onlyOwner 
    {
        IS_PUBLIC_SALE_ACTIVE = !IS_PUBLIC_SALE_ACTIVE;
    }

    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < MAX_SUPPLY, "Exceeds total supply");
        for (uint i = 0; i < numberOfTokens; i++) {
            mintInternal();
        }
    }
    

    function ogSale(uint256 quantity)
    public
    payable
    onlyAccounts
    {
        require(IS_OG_SALE_ACTIVE, "OGsale haven't started");
        uint current = _tokenIdCounter.current();
        require(current < MAX_SUPPLY, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + quantity <= NUMBER_OF_TOKENS_ALLOWED_PER_OG, "Exceeds allowance");
        require(msg.value >= MINT_PRICE * quantity, "Not enough money");
        mintInternal();
        
    }

    function preSale(uint256 quantity, bytes32[] calldata proof)
    public
    payable
    onlyAccounts
    {
        require(IS_PRE_SALE_ACTIVE, "Presale haven't started");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, root, leaf), "Invalid merkle proof");
        uint current = _tokenIdCounter.current();
        require(current < MAX_SUPPLY, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + quantity < NUMBER_OF_TOKENS_ALLOWED_PER_PRE, "Exceeds allowance");
        require(msg.value >= MINT_PRICE * quantity, "Not enough money");
        mintInternal();
        
    }

    function publicSale(uint256 quantity)
    public
    payable
    onlyAccounts
    {
        require(IS_PUBLIC_SALE_ACTIVE, "Publicsale haven't started");
        uint current = _tokenIdCounter.current();
        require(current < MAX_SUPPLY, "Exceeds total supply");
        require(addressToMintCount[msg.sender] + quantity < NUMBER_OF_TOKENS_ALLOWED_PER_PUBLIC, "Exceeds allowance");
        require(msg.value >= MINT_PRICE * quantity, "Not enough money");
        mintInternal();
        
    }

    function mintInternal() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        addressToMintCount[msg.sender]++;
        _mint(msg.sender, tokenId);
    }

    function withdrawFunds() public onlyOwner {
		payable(msg.sender).transfer(address(this).balance);
	}

    function tokenURI(uint256 tokenId)
        public
        view
        virtual
        override
        returns (string memory)
      {
        require(
          _exists(tokenId),
          "ERC721Metadata: URI query for nonexistent token"
        );
          return BASE_URI;      
      }

    function totalSupply() public view returns (uint) {
        return _tokenIdCounter.current() - 1;
    }

    function _leaf(address account, string memory payload)
    internal pure returns (bytes32)
    {
        return keccak256(abi.encodePacked(payload, account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof)
    internal view returns (bool)
    {
        return MerkleProof.verify(proof, root, leaf);
    }
}
