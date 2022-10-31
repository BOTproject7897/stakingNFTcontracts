// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.11;

// Import thirdweb contracts
import "@thirdweb-dev/contracts/drop/DropERC1155.sol";
import "@thirdweb-dev/contracts/token/TokenERC20.sol";
import "@thirdweb-dev/contracts/openzeppelin-presets/utils/ERC1155/ERC1155Holder.sol";

// OpenZeppelin (ReentrancyGuard)
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract StakingNftContract is ReentrancyGuard, ERC1155Holder {
    DropERC1155 public immutable editionNftCollection;
    TokenERC20 public immutable rewardsToken;

    constructor(
        DropERC1155 dropContractAddress,
        TokenERC20 tokenContractAddress
    ) {
        editionNftCollection = dropContractAddress;
        rewardsToken = tokenContractAddress;
    }

    struct MapValue {
        bool isData;
        uint256 value;
    }

    mapping(address => MapValue) public userMiner;

    mapping(address => MapValue) public userLastUpdate;

    function stake(uint256 _tokenId) external nonReentrant {
        require(
            editionNftCollection.balanceOf(msg.sender, _tokenId) >= 1,
            "You must have at least 1 of the NFT you are trying to stake"
        );

        if (userMiner[msg.sender].isData) {
            editionNftCollection.safeTransferFrom(
                address(this),
                msg.sender,
                userMiner[msg.sender].value,
                1,
                "Returning your old NFT"
            );
        }

        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        editionNftCollection.safeTransferFrom(
            msg.sender,
            address(this),
            _tokenId,
            1,
            "Staking your NFT"
        );

        userMiner[msg.sender].value = _tokenId;
        userMiner[msg.sender].isData = true;

        userLastUpdate[msg.sender].isData = true;
        userLastUpdate[msg.sender].value = block.timestamp;
    }

    function withdraw() external nonReentrant {
        require(
            userMiner[msg.sender].isData,
            "You do not have a NFT to withdraw."
        );

        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        editionNftCollection.safeTransferFrom(
            address(this),
            msg.sender,
            userMiner[msg.sender].value,
            1,
            "Returning your old NFT"
        );

        userMiner[msg.sender].isData = false;

        userLastUpdate[msg.sender].isData = true;
        userLastUpdate[msg.sender].value = block.timestamp;
    }

    function claim() external nonReentrant {
        uint256 reward = calculateRewards(msg.sender);
        rewardsToken.transfer(msg.sender, reward);

        userLastUpdate[msg.sender].isData = true;
        userLastUpdate[msg.sender].value = block.timestamp;
    }

    function calculateRewards(address _player)
        public
        view
        returns (uint256 _rewards)
    {
        if (
            !userLastUpdate[_player].isData || !userMiner[_player].isData
        ) {
            return 0;
        }

        uint256 timeDifference = block.timestamp -
            userLastUpdate[_player].value;

        uint256 rewards = timeDifference *
            10_000_000_000_000 *
            (userMiner[_player].value + 1);

        return rewards;
    }
}
