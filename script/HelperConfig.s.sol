// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;
//Deploy mocks when we are on a local anvil chain
//keep track of contract address across different chains
// sepolia ETH/USD
// Mainnet ETH/USD
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/Mocks/MockV3Aggregator.sol";

contract HelperConfig is Script {
    //Deploy mocks when we are on a local anvil chain
    //Otherwise, grab existing address from live chain network
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;
    NetworkConfig public activeNetworkConfig;
    struct NetworkConfig {
        address priceFeed; //ETH/USD priceFeed address
    }

    constructor() {
        if (block.chainid == 11155111) {
            activeNetworkConfig = getSepoliaEthConfig();
        } else if (block.chainid == 1) {
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            activeNetworkConfig = GetORCreateAnvilEthConfig();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory) {
        //priceFeed address
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        //priceFeed address
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: 0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419
        });
        return ethConfig;
    }

    function GetORCreateAnvilEthConfig() public returns (NetworkConfig memory) {
        if (activeNetworkConfig.priceFeed != address(0)) {
            return activeNetworkConfig;
        }
        // priceFeed
        // 1. Deploy Mock
        //2. return the Mock Address
        vm.startBroadcast();
        MockV3Aggregator mockpriceFeed = new MockV3Aggregator(
            DECIMALS,
            INITIAL_PRICE
        );
        vm.stopBroadcast();
        NetworkConfig memory AnvilConfig = NetworkConfig({
            priceFeed: address(mockpriceFeed)
        });
        return AnvilConfig;
    }
}
