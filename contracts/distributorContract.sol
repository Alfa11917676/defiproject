//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IGovernanceNFT.sol";
import "./IPool.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "hardhat/console.sol";
contract distributorContract is Ownable, ReentrancyGuard {

        struct nftDetails {
                uint poolId;
                uint termId;
                uint weightageEquivalent;
                uint stakeAmount;
                uint stakeTime;
                uint lastClaimTime;
                address _currentOwner;
                address _tokenAddress;
        }
        address public insuranceFundAddress;
        uint public minimumTimeQuantum = 1 days;
        address[4] public collectionPools;
        address[4] public governanceTokenAddress;
        uint[4] public nftIndexPerPool = [0,0,0,0];
        uint[4] public aprPercent = [0,25,50,100]; //2.5%,5%,10%
        uint[4] public weightageCalculationPercentagePerPool = [0,200,150,100];
        uint[3] public lockQuantumPerPool = [0,10 days, 20 days];
        // tokenId => poolId => nftDetails
        mapping (uint =>  mapping( uint => nftDetails)) detailsPerNftId;
        mapping (uint => mapping (address => uint)) poolMapper;
        mapping (address => bool) public authorisedCaller;
        mapping (address => bool) public whitelistedTokens;
        // user => tokenAddress => poolId => termId
        mapping (address => mapping (address => mapping (uint => uint))) public currentTermIdForUserPerPool;

        function deposit (uint poolId, address tokenAddress, uint tokenAmount) external nonReentrant {
                require (poolId > 0 && poolId < 4, 'Error: Invalid Pool Ids');
                require (whitelistedTokens[tokenAddress],'Error: Token Not Whitelisted');
                uint tokenAmounts = tokenAmount * 1 ether;
                uint termId = ++currentTermIdForUserPerPool[msg.sender][tokenAddress][poolId];
                uint weightageEquivalent = calculateGovernanceToken(poolId, tokenAmount);
                uint currentIndexOfPool = nftIndexPerPool[poolId]+1;
                ++nftIndexPerPool[poolId];
                poolMapper[currentIndexOfPool][governanceTokenAddress[poolId]] = poolId;
                if (poolId == 1) {
                        uint insuranceAmount = tokenAmounts - (tokenAmounts * (1000-250))/1000;
                        tokenAmounts -= insuranceAmount;
                        IERC20(tokenAddress).transferFrom(msg.sender, insuranceFundAddress, insuranceAmount);
                }
                nftDetails storage details = detailsPerNftId[currentIndexOfPool][poolId];
                details.poolId =poolId;
                details.termId =termId;
                details.weightageEquivalent =weightageEquivalent;
                details.stakeAmount = tokenAmounts;
                details.stakeTime = block.timestamp;
                details.lastClaimTime = block.timestamp;
                details._currentOwner =msg.sender;
                details._tokenAddress =tokenAddress;
                IERC20(tokenAddress).transferFrom(msg.sender, collectionPools[poolId], tokenAmounts);
                IGovernanceNFT(governanceTokenAddress[poolId]).mintTokens(msg.sender, nftIndexPerPool[poolId]);
        }

        function claimFunds (uint[] memory poolIds, uint[] memory _nftIds) external nonReentrant {
                require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
                for (uint i=0; i< poolIds.length; i++) {
                        require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i]) == msg.sender,'Error: Caller Not Owner');
                        uint amount = getRewardDetails(poolIds[i], _nftIds[i]);
                        nftDetails storage details = detailsPerNftId[_nftIds[i]][poolIds[i]];
                        details.lastClaimTime = block.timestamp;
                        require(amount > 0 ,'Error: Not Enough Reward Collected');
                        IPool(collectionPools[poolIds[i]]).payRewards(msg.sender, amount);
                }
        }

        function unstakeTokens (uint[] memory poolIds, uint[] memory _nftIds) external nonReentrant {
                require(poolIds.length == _nftIds.length,'Error: Array length Not Equal');
                for (uint i=0; i< poolIds.length; i++) {
                        require (IGovernanceNFT(governanceTokenAddress[poolIds[i]]).ownerOf(_nftIds[i])==msg.sender,'Error: Caller Not Owner');
                        uint poolId = poolIds[i];
                        address tokenAddress = detailsPerNftId[_nftIds[i]][poolId]._tokenAddress;
                        uint amountToReturn = detailsPerNftId[_nftIds[i]][poolId].stakeAmount;
                        require (block.timestamp > detailsPerNftId[_nftIds[i]][poolId].stakeTime + lockQuantumPerPool[poolId],'Error: Lock Period Not Over');
                        delete currentTermIdForUserPerPool[msg.sender][tokenAddress][poolId];
                        delete poolMapper[_nftIds[i]][governanceTokenAddress[poolId]];
                        delete detailsPerNftId[_nftIds[i]][poolId];
                        IGovernanceNFT(governanceTokenAddress[poolId]).burnTokens(_nftIds[i]);
                        IPool(collectionPools[poolId]).transferFunds(tokenAddress,msg.sender,amountToReturn);
                }
        }

        function getRewardDetails(uint poolId, uint _nftId) public view returns(uint) {
                uint amount = detailsPerNftId[_nftId][poolId].stakeAmount;
                uint lastClaimTime = detailsPerNftId[_nftId][poolId].lastClaimTime;
                uint finalAmount;
                uint time;
                if (block.timestamp > lastClaimTime + minimumTimeQuantum)
                {
                        finalAmount = (amount - ((amount * (1000 - aprPercent[poolId])) / 1000));
                        time = (block.timestamp - lastClaimTime + minimumTimeQuantum)/minimumTimeQuantum;

                }
                return time * finalAmount;
        }

        function calculateGovernanceToken(uint poolId, uint tokenAmount) internal view returns(uint) {
                return (tokenAmount * weightageCalculationPercentagePerPool[poolId]) / 1000;
        }

        function viewNftDetails (uint tokenId, uint poolId) external view returns(nftDetails memory) {
                return detailsPerNftId[tokenId][poolId];
        }

        function addCollectionPoolAddresses (address pool1, address pool2, address pool3) external onlyOwner {
                collectionPools = [address(0),pool1,pool2,pool3];
        }

        function addGovernanceTokenAddress (address _pool1GovernanceToken, address _pool2GovernanceToken, address _pool3GovernanceToken) external onlyOwner {
                governanceTokenAddress = [address(0),_pool1GovernanceToken,_pool2GovernanceToken,_pool3GovernanceToken];
        }

        function addInsuranceFundAddress (address _insuranceFundAddress) external onlyOwner {
                insuranceFundAddress = _insuranceFundAddress;
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

        function addAuthorisedCaller(address _caller) external onlyOwner {
                authorisedCaller[_caller] = true;
        }

        function removeAuthorisedCaller(address _caller) external onlyOwner {
                authorisedCaller[_caller] = false;
        }

        function changeMinimumQuantum(uint time) external onlyOwner {
                minimumTimeQuantum = time;
        }

        function changeLockQuantumPerPool(uint[3] memory time) external onlyOwner {
                lockQuantumPerPool = time;
        }

        function changeAPR(uint[4] memory apr) external onlyOwner {
                aprPercent = apr;
        }

        function changeWeightageCalculationPercentagePerPool(uint[4] memory weightage) external onlyOwner {
                weightageCalculationPercentagePerPool = weightage;
        }

        function changeDetailsOfInvestors(address _to, address _nftAddress, uint _tokenId) external {
                require (authorisedCaller[msg.sender],'Error: Caller Not Authorised');
                uint poolId = poolMapper[_tokenId][_nftAddress];
                address _tokenAddress = detailsPerNftId[_tokenId][poolId]._tokenAddress;
                uint newTermId = ++currentTermIdForUserPerPool[_to][_tokenAddress][poolId];
                nftDetails storage details = detailsPerNftId[_tokenId][poolId];
                details._currentOwner = _to;
                details.termId = newTermId;
        }
}

//todo: Write deployment script for the contracts
//todo: Add comment in the code to increase readability

