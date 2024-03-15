// SPDX-License-Identifier: MIT
pragma solidity 0.8.22;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract TestFundMe is Test {
    FundMe public fundMe;
    DeployFundMe public deployFundMe;
    uint256 public amountFunded;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 5 ether;
    uint256 constant MIN_USD = 5e18;

    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        deal(USER, STARTING_BALANCE);
    }

    function testMinimumDollarsIs5() public {
        assertEq(fundMe.MINIMUM_USD(), MIN_USD);
    }

    function testOwnerIsMsgSsender() public {
        console.log(fundMe.getOwner());
        console.log(msg.sender);
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceVersionFeedIsAccurate() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function test_FailsIfFundsIsNotEnough() public {
        vm.expectRevert(); //the next line of code should revert!
        //assert (this trx fails)
        fundMe.fund(); // send 0
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); // the next TRX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        amountFunded = fundMe.getAddressToAmontFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // the next TRX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER); // the next TRX will be sent by USER
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(USER);
        fundMe.withdraw();
    }

    function testWithdrawASingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawForMultipleFunders() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint160 numberOfFunders = 10;
        uint160 startFunderIndex = 1;
        for (uint160 i = startFunderIndex; i < numberOfFunders; i++) {
            //vm.prank new address
            //vm.deal new address
            //address()
            hoax(address(i), SEND_VALUE);

            //Act
            vm.startPrank(fundMe.getOwner());
            fundMe.withdraw();
            vm.stopPrank();
            //assert

            uint256 endingOwnerBalance = fundMe.getOwner().balance;
            uint256 endingFundMeBalance = address(fundMe).balance;
            assertEq(endingFundMeBalance, 0);
            assertEq(
                startingFundMeBalance + startingOwnerBalance,
                endingOwnerBalance
            );
        }
    }
}
