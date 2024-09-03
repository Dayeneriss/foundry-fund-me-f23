//SPDX-License-Identifier: MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    //Test contract
    // 1. Pragma
    // 2. Imports
    // 3. Interfaces, Libraries, Contracts
    // 4. State variables
    // 5. Events
    // 6. Modifiers
    // 7. Functions Order
    // 8. Constructor
    // 9. Fall back
    // 10. Receive
    // 11. External
    // 12. Public
    // 13. Internal
    // 14. Private
    // 15. View / Pure
    // 16. Test functions
    // 17. Helper functions
    FundMe fundMe;

    DeployFundMe deployFundMe;

    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether; //100000000000000000 wei
    uint256 constant STARTING_BALANCE = 10 ether; // 5 USD in wei assuming 1 ETH = $2000
    uint256 constant GAS_PRICE = 1;

    function setUp() external { 
       
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }
        //fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);   
    function testMinimumDollarIsFive() public view {
        uint256 minimumUsd = fundMe.MINIMUM_USD();
        assertEq(minimumUsd, 5e18, "MINIMUM_USD should be 5e18");
    }
    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender, "Owner should be the msg.sender");
    } 
    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }
    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); //hey, the next line, should revert
        //assert(This tx fails/reverts) 
        fundMe.fund(); //send 0 value       
    }
    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER); //pretend to be USER
        fundMe.fund{value: SEND_VALUE}(); 

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); //pretend to be USER
        fundMe.fund{value: SEND_VALUE}(); 

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }
// cf chap 15 et twitter : L'idée c'est de créer un mofier pour éviter de répéter les mêmes tests sans arrêts ; 
//Ecrire moins de codes pour plus de résultats de tests. Ici le modifier évite d'écrire à chaque fois "vm.prank(USER); fundMe.fund{value: SEND_VALUE}();" 
    modifier funded() {
        vm.prank(USER); //pretend to be USER
        fundMe.fund{value: SEND_VALUE}(); 
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.prank(USER); //pretend to be USER
        vm.expectRevert(); //hey, the next line, should revert
        fundMe.withdraw(); //send 0 value       
    }
    function testWithdrawWithSingerFunder() public funded {
        // Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;
        
        // Act
        uint256 gasStart = gasleft();
        vm.txGasPrice(GAS_PRICE);
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 gasEnd = gasleft();
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("Gas used: ", gasUsed);

        // Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }
    function testWithdrawFromMultipleFunders() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank
            // vm.deal new address
            // address()
            hoax(address(i),SEND_VALUE); 
            fundMe.fund{value: SEND_VALUE}();
            // fund the fundMe 
        }
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        //Assert
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}

