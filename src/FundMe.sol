// SPDX-License-Identifier: MIT

// Smart contract that lets anyone deposit ETH into the contract
// Only the owner of the contract can withdraw the ETH
pragma solidity 0.8.22;

// Get the latest ETH/USD price from chainlink price feed

// IMPORTANT: This contract has been updated to use the Goerli testnet
// Please see: https://docs.chain.link/docs/get-the-latest-price/
// For more information

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "../src/PriceConverter.sol";
error FundMe_NotOwner();

contract FundMe {
    // safe math library check uint256 for integer overflows
    using PriceConverter for uint256;

    //mapping to store which address depositeded how much ETH
    mapping(address => uint256) private s_addressToAmountFunded;
    // array of addresses who deposited
    address[] private s_funders;
    //address of the owner (who deployed the contract)
    address private immutable i_owner;
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    AggregatorV3Interface private s_priceFeed;

    // the first person to deploy the contract is
    // the owner
    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // 18 digit number to be compared with donated amount

        //is the donated amount less than 50USD?
        require(
            getConversionRate(msg.value) >= MINIMUM_USD,
            "You need to spend more ETH!"
        );
        //if not, add to mapping and funders array
        s_addressToAmountFunded[msg.sender] += msg.value;
        s_funders.push(msg.sender);
    }

    //function to get the version of the chainlink pricefeed
    function getVersion() external view returns (uint256) {
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     (0x694AA1769357215DE4FAC081bf1f309aDC325306)
        // );
        return s_priceFeed.version();
    }

    function getPrice() private view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            (0x694AA1769357215DE4FAC081bf1f309aDC325306)
        );
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // ETH/USD rate in 18 digit
        return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(
        uint256 ethAmount
    ) private view returns (uint256) {
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        // the actual ETH/USD conversation rate, after adjusting the extra 0s.
        return ethAmountInUsd;
    }

    //modifier: https://medium.com/coinmonks/solidity-tutorial-all-about-modifiers-a86cf81c14cb
    modifier onlyOwner() {
        //is the message sender owner of the contract?
        require(msg.sender == i_owner);

        _;
    }

    // onlyOwner modifer will first check the condition inside it
    // and
    // if true, withdraw function will be executed
    function withdraw() external payable onlyOwner {
        payable(address(msg.sender)).transfer;

        //iterate through all the mappings and make them 0
        //since all the deposited amount has been withdrawn
        for (
            uint256 funderIndex = 0;
            funderIndex < s_funders.length;
            funderIndex++
        ) {
            address funder = s_funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        //funders array will be initialized to 0
        s_funders = new address[](0);

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed");
    }

    fallback() external payable {
        fund();
    }

    receive() external payable {
        fund();
    }

    // view/pure fucntion (Getters)
    function getAddressToAmontFunded(
        address fundingAddresss
    ) external view returns (uint256) {
        return s_addressToAmountFunded[fundingAddresss];
    }

    function getFunder(uint256 index) external view returns (address) {
        return s_funders[index];
    }

    function getOwner() external view returns (address) {
        return i_owner;
    }
}
