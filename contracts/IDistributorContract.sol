//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IDistributorContract {
    function changeDetailsOfInvestors(address _to, address _nftAddress, uint _tokenId) external;
}
