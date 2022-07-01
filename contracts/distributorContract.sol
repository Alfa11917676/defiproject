//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
contract distributorContract is Ownable, ReentrancyGuard {

        address public collectionPool1;
        address public collectionPool2;
        address public collectionPool3;
        address public insuranceFundAddress;

        IERC20 governanceToken;
        IERC20 rewardToken;

        constructor (address _rewardTokenAddress) {
                rewardToken = IERC20(_rewardTokenAddress);
        }

        struct userDetails {
                mapping (uint => uint) tokensInPool1;
                mapping (uint => uint) tokensInPool2;
                mapping (uint => uint) tokensInPool3;
        }

        mapping (address => bool) public whitelistedTokens;
        mapping (address => userDetails) userPoolDetails;
        // user => poolType => termId => stakeTime
        mapping (address => mapping ( address => mapping (uint => mapping (uint => uint)))) public stakeTimeInPoolPerTermId;
        // user => poolType => termId => lastClaimTime
        mapping (address => mapping ( address => mapping (uint => mapping (uint => uint)))) public lastClaimInPoolPerTermId;
        // user => poolType => termId => amount
        mapping (address => mapping ( address => mapping(uint => mapping (uint => uint)))) public userTokensLockedPerId;
        // user => poolId => termId
        mapping (address => mapping ( address => mapping (uint => uint))) public userTermIdPerPool;

        uint[4] public poolPercent = [0,200,150,100];
        uint[3] public lockQuantumPerPool = [0,10 days, 20 days];
        uint public minimumTimeQuantum = 1 days;


        function deposit (uint poolId, address _tokenAddress, uint tokenAmount) external {
                require (poolId > 0 && poolId < 4, 'Error: Invalid Pool Ids');
                require (whitelistedTokens[_tokenAddress],'Error: Token Not Whitelisted');
                uint tokenAmounts = tokenAmount * 1 ether;
                uint termId = ++userTermIdPerPool[msg.sender][_tokenAddress][poolId];
                userTokensLockedPerId[msg.sender][_tokenAddress][poolId][termId] = tokenAmounts;
                stakeTimeInPoolPerTermId[msg.sender][_tokenAddress][poolId][termId] = block.timestamp;
                lastClaimInPoolPerTermId[msg.sender][_tokenAddress][poolId][termId] = block.timestamp;
                userDetails storage details = userPoolDetails[msg.sender];
                details.tokensInPool1[poolId]+=tokenAmounts;
                uint amount = calculateGovernanceToken(poolId, tokenAmounts);
                if (poolId == 1) {
                        uint insuranceAmount = tokenAmount - (tokenAmount * (1000-250))/1000;
                        tokenAmount -= insuranceAmount;
                        IERC20(_tokenAddress).transferFrom(msg.sender, insuranceFundAddress, insuranceAmount);
                }
                IERC20(_tokenAddress).transferFrom(msg.sender, collectionPool1, tokenAmount);
                IERC20(governanceToken).transfer(msg.sender, amount);
        }

        function getRewardDetails(address _user, address _tokenAddress, uint poolId, uint termId) public view returns(uint) {
                uint  amount = userTokensLockedPerId[_user][_tokenAddress][poolId][termId];
                uint finalAmount;
                if (poolId == 1) {
                        if (block.timestamp > lastClaimInPoolPerTermId[_user][_tokenAddress][poolId][termId] + minimumTimeQuantum)
                                finalAmount =  (amount - ((amount * (1000 - 25))/1000 ));
                } else if (poolId == 2) {
                        if (block.timestamp > lastClaimInPoolPerTermId[_user][_tokenAddress][poolId][termId] + minimumTimeQuantum)
                                finalAmount = (amount - ((amount * (1000 - 50))/1000 ));
                } else {
                        if (block.timestamp > lastClaimInPoolPerTermId[_user][_tokenAddress][poolId][termId] + minimumTimeQuantum)
                                finalAmount = (amount - ((amount * (1000 - 100))/1000 ));
                }
                return finalAmount;
        }

        function claimFunds (uint[] memory poolIds, address[] memory _nftAddresses, uint[] memory termIds) external nonReentrant {
                require(poolIds.length == termIds.length,'Error: Array length Not Equal');
                uint totalRewardAmount;
                for (uint i=0; i< poolIds.length; i++) {
                        uint amount = getRewardDetails(msg.sender, _nftAddresses[i], poolIds[i], termIds[i]);
                        totalRewardAmount+= amount;
                }
                require(totalRewardAmount > 0,'Error: Not Enough Reward Collected');
                rewardToken.transfer(msg.sender, totalRewardAmount);
        }

        function unstakeTokens (uint[] memory poolIds, address[] memory _nftAddresses,  uint[] memory termIds) external nonReentrant {
                require(poolIds.length == termIds.length,'Error: Array length Not Equal');
                for (uint i=0; i< poolIds.length; i++) {
                        require (block.timestamp > stakeTimeInPoolPerTermId[msg.sender][_nftAddresses[i]][poolIds[i]][termIds[i]] + lockQuantumPerPool[poolIds[i]],'Error: Lock Period Not Over');
                        delete stakeTimeInPoolPerTermId[msg.sender][_nftAddresses[i]][poolIds[i]][termIds[i]];
                        delete lastClaimInPoolPerTermId[msg.sender][_nftAddresses[i]][poolIds[i]][termIds[i]];
                        uint amountToReturn = userTokensLockedPerId[msg.sender][_nftAddresses[i]][poolIds[i]][termIds[i]];
                        delete userTokensLockedPerId[msg.sender][_nftAddresses[i]][poolIds[i]][termIds[i]];
                        IERC20(_nftAddresses[i]).transfer(msg.sender,amountToReturn);
                }
        }

        function calculateGovernanceToken(uint poolId, uint tokenAmount) internal view returns(uint) {
                return (tokenAmount * poolPercent[poolId]) / 1000;
        }

        function addCollectionPoolAddresses (address pool1, address pool2, address pool3) external onlyOwner {
                collectionPool1 = pool1;
                collectionPool2 = pool2;
                collectionPool3 = pool3;
        }

        function addGovernanceTokenAddress (address _governanceTokenAddress) external onlyOwner {
                governanceToken = IERC20(_governanceTokenAddress);
        }

        function addInsuranceFundAddress (address _insuranceFundAddress) external onlyOwner {
                insuranceFundAddress = _insuranceFundAddress;
        }

        function setRewardTokenAddress (address _rewardTokenAddress) external onlyOwner {
                rewardToken = IERC20(_rewardTokenAddress);
        }

        function whitelistTokenAddresses (address[] memory addresses) external onlyOwner {
                for (uint i =0; i<addresses.length; i++) {
                        require (!whitelistedTokens[addresses[i]], 'Error: Already Whitelisted');
                        whitelistedTokens[addresses[i]] = true;
                }
        }

        function blackListWhitelistedTokenAddresses (address[] memory addresses) external onlyOwner {
                for (uint i =0; i<addresses.length; i++) {
                        require (whitelistedTokens[addresses[i]], 'Error: Already BlackListed or Never Whitelisted');
                        whitelistedTokens[addresses[i]] = false;
                }
        }

        function seeUserDetails (address _user) external view returns (uint, uint, uint) {
                        return (
                        userPoolDetails[_user].tokensInPool1[1],
                        userPoolDetails[_user].tokensInPool2[2],
                        userPoolDetails[_user].tokensInPool3[3]
                        );
        }

}
