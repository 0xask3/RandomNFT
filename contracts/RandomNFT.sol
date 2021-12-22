// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNFT is ERC1155, VRFConsumerBase, Ownable {
    uint8 public constant GENESIS = 0;
    uint8 public constant F1 = 1;
    uint8 public constant F2 = 2;

    uint8 public numberOfWinners = 33;
    uint16 public totalGenesisToBeMinted = 1500;

    IERC721Enumerable public nftContract;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    uint256 private oldResult;

    mapping(uint16 => bool) public isAlreadyMinted;
    mapping(uint16 => address) public minterOf;

    //Setup for rinkeby as of now.
    constructor(address _nftContract)
        ERC1155("Put Random value here while deploying. Changeable later")
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        nftContract = IERC721Enumerable(_nftContract);
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10**18; // 0.1 LINK (Varies by network)
    }

    //Airdrop function which can airdrop F1 to NFTContract holders
    function airdrop() external onlyOwner {
        require(randomResult != oldResult, "Update random number first");
        uint256 totalHolders = nftContract.totalSupply();
        uint256 tempRandom;

        _mint(address(this), F1, numberOfWinners, "");

        for (uint8 i = 0; i < numberOfWinners; i++) {
            tempRandom = randomResult;
            uint256 winnerId = randomResult % totalHolders;
            address winner = nftContract.ownerOf(winnerId);
            _mint(winner, F1, 1, "");
            randomResult = uint256(
                keccak256(
                    abi.encodePacked(tempRandom, block.timestamp, winnerId)
                )
            );
        }

        oldResult = randomResult;
    }

    //Mint function to mint tokens with other ids later
    function mintByOwner(uint8 id, uint256 amount) external onlyOwner {
        _mint(msg.sender, id, amount, "");
    }

    //Mint function for users to mint GENESIS if they hold other NFT
    //Here id would be the id of NFT they hold
    function mintByUser(uint16 id) external {
        require(id < totalGenesisToBeMinted,"Invalid token id");
        require(nftContract.ownerOf(id) == msg.sender,"You don't own corresponding NFT");
        require(!isAlreadyMinted[id],"GENESIS mint already made for this NFT");

        _mint(msg.sender, GENESIS, 1, "");
        isAlreadyMinted[id] = true;
        minterOf[id] = msg.sender;
    }

    //Burn function which can be called by anyone to burn their balance
    function burn(uint8 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    //Number of winners of NFTContract per airdrop. Max possible value is 256, to control gas usage
    function setWinnerCount(uint8 amount) external onlyOwner {
        numberOfWinners = amount;
    }

    //Number of GENESIS which can be minted by users 
    function setMaxGenesisCount(uint16 amount) external onlyOwner {
        totalGenesisToBeMinted = amount;
    }

    //Random number generator function. Must be called before doing airdrop
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(
            LINK.balanceOf(address(this)) >= fee,
            "Not enough LINK - fill contract with faucet"
        );
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness)
        internal
        override
    {
        randomResult = randomness;
        requestId = 0;
    }
}
