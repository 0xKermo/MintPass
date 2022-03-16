// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract mintPass is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;
    
    bytes32 public root; // who can mint?
    
    string BASE_URI; // What will my mintPass look like?
    
    bool public IS_SALE_ACTIVE = false; // can we mint?
    
    uint public constant MAX_SUPPLY = 9999; //  MAX_SUPPLY - My mintPass = number of siblings of my mintPass

    uint constant NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS = 1; // How many can I mint from this mintPass?
        
    mapping (address => uint256) addressToMintCount; // how many mint passes do i have
    mapping (address => uint256) public addressToTokenId;

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

     function burn(uint256 tokenId) public virtual {
        require(_isApprovedOrOwner(_msgSender(), tokenId), "caller is not owner nor approved");
        _burn(tokenId);
        _tokenIdCounter.decrement();
        delete addressToTokenId[msg.sender];
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

    function toggleSale() public 
    onlyOwner 
    {
        IS_SALE_ACTIVE = !IS_SALE_ACTIVE;
    }
  
    function ownerMint(uint numberOfTokens) 
    public 
    onlyOwner {
        uint current = _tokenIdCounter.current();
        require(current + numberOfTokens < MAX_SUPPLY, "Exceeds total supply");

        for (uint i = 0; i < numberOfTokens; i++) {
            mintPrivate();
        }
    }

    function privateSale(address account,  bytes32[] calldata proof)
    public
    onlyAccounts
    {
        require(msg.sender == account, "Not allowed");
        require(IS_SALE_ACTIVE, "Privatesale haven't started");
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, root, leaf), "Invalid merkle proof");
        uint current = _tokenIdCounter.current();
        require(current < MAX_SUPPLY, "Exceeds total supply");
        require(addressToMintCount[msg.sender] < NUMBER_OF_TOKENS_ALLOWED_PER_ADDRESS, "Exceeds allowance");
        mintPrivate();
        
    }

    function mintPrivate() internal {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        addressToTokenId[msg.sender] = tokenId;
        addressToMintCount[msg.sender]++;
        _mint(msg.sender, tokenId);
    }

    function ownerTokenId(address _owner) external view returns(uint256){
            return addressToTokenId[_owner];
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