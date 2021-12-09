// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/interfaces/IERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract RandomNFT is ERC1155, VRFConsumerBase, Ownable {
    uint256 public constant GENESIS = 0;
    uint256 public constant F1 = 1;
    uint256 public constant F2 = 2;

    IERC721Enumerable public NFT;

    bytes32 internal keyHash;
    uint256 internal fee;
    uint256 public randomResult;
    uint256 private oldResult;

    uint8 public numberOfWinners = 33;

    //Setup for rinkeby as of now. 
    constructor(address nftContract)
        ERC1155("Put URI Here")
        VRFConsumerBase(
            0xb3dCcb4Cf7a26f6cf6B120Cf5A73875B7BBc655B, // VRF Coordinator
            0x01BE23585060835E02B77ef475b0Cc51aA1e0709 // LINK Token
        )
    {
        _mint(address(this), GENESIS, 1000, "");
        NFT = IERC721Enumerable(nftContract);
        keyHash = 0x2ed0feb3e7fd2022120aa84fab1945545a9f2ffc9076fd6156fa96eaff4c1311;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    //Random number generator function. Must be called before doing airdrop
    function getRandomNumber() public onlyOwner returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee, "Not enough LINK - fill contract with faucet");
        return requestRandomness(keyHash, fee);
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
        requestId = 0;
    }

    //Airdrop function which can airdrop GENESIS to NFT holders
    function airdrop() external onlyOwner {
        require(randomResult != oldResult,"Update random number first");
        uint256 totalHolders = NFT.totalSupply();
        uint256 tempRandom;

        for(uint8 i = 0; i < numberOfWinners; i++){
            tempRandom = randomResult;
            uint256 winnerId = randomResult % totalHolders;
            address winner = NFT.ownerOf(winnerId);
            _safeTransferFrom(address(this), winner, 0, 1, ""); 
            randomResult = uint(keccak256(abi.encodePacked(tempRandom, block.timestamp, winnerId)));
        }

        oldResult = randomResult;
    }

    //Mint function to mint tokens with other ids later
    function mint(uint8 id, uint256 amount) external onlyOwner {
        _mint(msg.sender, id, amount, "");
    } 

    //Burn function which can be called by anyone to burn their balance
    function burn(uint8 id, uint256 amount) external {
        _burn(msg.sender, id, amount);
    }

    //Number of winners of NFT per airdrop. Max possible value is 256, to control gas usage
    function setWinnerCount(uint8 amount) external onlyOwner {
        numberOfWinners = amount;
    }
}
