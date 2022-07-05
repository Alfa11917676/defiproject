//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IPool {
    function transferFunds(address _tokenAddress, address _to, uint _amount ) external;
    function payRewards(address _to, uint _amount ) external;
}
