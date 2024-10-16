//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// 1. 创建一个收款函数
// 2. 记录投资人并且查看
// 3. 在锁定期内，达到目标值，生产商可以提款
// 4. 在锁定期内，没有达到目标值，投资人在锁定期以后退款

contract FundMe {
    mapping(address => uint256) public fundersToAmount;

    uint256 constant MINIMUM_VALUE = 10 * 10 ** 18; //USD
    
    AggregatorV3Interface internal dataFeed;

    uint256 constant TARGET = 100 * 10 ** 18;

    address public owner;

    constructor() {
        // sepolia testnet
        dataFeed = AggregatorV3Interface(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        owner = msg.sender;
    }

    function fund() external payable {
        require(convertEthToUsd(msg.value) >= MINIMUM_VALUE, "Send more ETH");
        fundersToAmount[msg.sender] = msg.value;
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int) {
        // prettier-ignore
        (
            /* uint80 roundID */,
            int answer,
            /*uint startedAt*/,
            /*uint timeStamp*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

    function convertEthToUsd(uint256 ethAmount) internal view returns(uint256){
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer());
        return ethAmount * ethPrice / (10 ** 8);
    }

    function transferOwnership(address newOwner) public{
        require(msg.sender == owner, "you do not have permission to call this funtion");
        owner = newOwner;
    }

    function getFund() external {
        require(convertEthToUsd(address(this).balance) >= TARGET, "Target is not reached");
        // transfer: transfer ETH and revert if tx failed
        //payable(msg.sender).transfer(address(this).balance);
        
        // send: transfer ETH and return false if failed
        // bool success = payable(msg.sender).send(address(this).balance);
        // require(success, "tx failed");
        bool success;
        (success, ) = payable(msg.sender).call{value: address(this).balance}("");
        require(success, "transfer tx failed");
        
        // call: transfer ETH with data return value of function and bool 
        // bool success;
        // (success, ) = payable(msg.sender).call{value: address(this).balance}("");
        // require(success, "transfer tx failed");
        // fundersToAmount[msg.sender] = 0;
        // getFundSuccess = true; // flag
    }

}