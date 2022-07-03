//SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
interface IGovernanceNFT is IERC721 {
    function mintTokens(address _to, uint tokenId) external;
    function burnTokens(uint tokenId) external;
}
