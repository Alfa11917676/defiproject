//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./IDistributorContract.sol";
contract governanceToken is ERC721, Ownable {

    IDistributorContract public distributorAddress;

    constructor (string memory tokenName, string memory tokenSymbol) ERC721(tokenName, tokenSymbol) {}

    mapping (address => bool) public isAuthorised;
    function mintTokens(address _to, uint tokenId) external {
        require (isAuthorised[msg.sender],'Error: Caller Not Authorised');
        _mint (_to, tokenId);
    }

    function burnTokens(uint tokenId) external {
        require (isAuthorised[msg.sender],'Error: Caller Not Authorised');
        _burn (tokenId);
    }

    function addAuthorisedMinter (address _minter) external onlyOwner {
        isAuthorised[_minter] = true;
    }

    function removeAuthorisedMinter (address _minter) external onlyOwner {
        isAuthorised[_minter] = false;
    }

    function addDistributorAddress (address _distributor) external onlyOwner {
        distributorAddress = IDistributorContract(_distributor);
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override virtual {
        if (from != address(0) && to != address(0))
            distributorAddress.changeDetailsOfInvestors(to,address(this),tokenId);
        super._beforeTokenTransfer(from, to, tokenId);
    }
}
