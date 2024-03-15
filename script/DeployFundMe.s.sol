// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";

contract DeployFundMe is Script {
    FundMe public fundMe;
    HelperConfig public helperConfig;
    address public ethUsdpriceFeed;

    function run() external returns (FundMe) {
        helperConfig = new HelperConfig();
        ethUsdpriceFeed = helperConfig.activeNetworkConfig();
        vm.startBroadcast();
        fundMe = new FundMe(ethUsdpriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
