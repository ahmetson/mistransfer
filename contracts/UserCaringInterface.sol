interface UserCaringInterface {
    function recoverUserNft(address nftAddress, address to, uint tokenId) external; // invoked by the
    function recoverUserToken(address token, address to, uint amount) external;
    function setCaringSupporter(address newOwner) external; // change the address that receives the reward.
    function caringSupporter() external returns(address);
}