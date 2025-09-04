// SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {PriceConverter} from "./PriceConverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5e18;
    address private immutable I_OWNER;
    AggregatorV3Interface private s_priceFeed;

    mapping(address funder => uint256 amountFunded) private s_addressToAmountFunded;
    address[] private s_funders;

    constructor(address priceFeed) {
        I_OWNER = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD, "You do not deposit sufficient ETH");
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 fundersLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < fundersLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);
        (bool callSuccess,) = payable(I_OWNER).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex]; // getting funder address from storage
            s_addressToAmountFunded[funder] = 0;
            /**
             * emptying the amount funded
             */
        }
        s_funders = new address[](0); // reseting the array

        //call option for withdrawal
        (bool callSuccess,) = payable(I_OWNER).call{value: address(this).balance}("");
        require(callSuccess, "Call Failed");
    }

    function getVersion() public view returns (uint256) {
        // AggregatorV3Interface(s_priceFeed); xyz
        return s_priceFeed.version();
    }

    modifier onlyOwner() {
        if (msg.sender != I_OWNER) revert FundMe__NotOwner();
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    /**
     * getter functions**
     */
    function getAddressToAmountFunded(address fundingAddress) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return I_OWNER;
    }
}
