//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
contract poolContract is Ownable {

    mapping (address => bool) public authorisedCaller;

    function addAuthorisedCaller(address _caller) external onlyOwner {
        authorisedCaller[_caller] = true;
    }

    function removeAuthorisedCaller(address _caller) external onlyOwner {
        authorisedCaller[_caller] = false;
    }

    function transferFunds(address _tokenAddress, address _to, uint _amount ) external {
        require (authorisedCaller[msg.sender],'Error: Caller Not Authorised');
        IERC20(_tokenAddress).transfer(_to, _amount);
    }

    function withDrawFunds(address _tokenAddress, uint amount) external onlyOwner {
        IERC20(_tokenAddress).transfer(msg.sender, amount);
    }

}
