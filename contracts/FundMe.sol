// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

//imports
import "./PriceConvertor.sol";

//error codes

error FundMe__NotOwner();
error FundMe__NotEnoughSent();

//interface, libraries, contracts

/**
 * @title A contract for crowd funding
 * @author Dexconv
 * @notice this contract is to demmo sammple funding contract
 * @dev this implements pricefeeds as our library
 */
contract FundMe {
    // type declaration
    using PriceConvertor for uint256;

    // state vaiables
    mapping(address => uint256) private s_addressToAmountFunded;
    uint256 public constant MINIMUM_USD = 50 * 1e18;
    address[] private s_funders;
    address private immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    modifier onlyOwner() {
        //require(msg.sender == iOwner, "sender is not the owner!");
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    /**
     * @notice this function funds this contract
     * @dev this implements pricefeeds as our library
     */
    function fund() public payable {
        /* require(
            msg.value.getConversionRate(s_priceFeed) >= MINIMUM_USD,
            "not enough sent!"
        ); //1e18 = 1eth */

        if (msg.value.getConversionRate(s_priceFeed) <= MINIMUM_USD) {
            revert FundMe__NotEnoughSent();
        }

        s_funders.push(msg.sender);
        s_addressToAmountFunded[msg.sender] = msg.value;
    }

    function withdraw() public payable onlyOwner {
        for (uint256 i = 0; i < s_funders.length; i++) {
            address founder = s_funders[i];
            s_addressToAmountFunded[founder] = 0;
        }
        s_funders = new address[](0);

        //withdraw the funds

        //automatically revevrts
        //payable(msg.sender).transfer(address(this).balance);

        //returns a bool and should use require to revert
        //bool sendSuccess = payable(msg.sender).send(address(this).balance);
        //require(sendSuccess, "send failed!");

        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "call failed!");
    }

    function cheaperWithdraw() public payable onlyOwner {
        address[] memory funders = s_funders;
        for (uint256 i = 0; i < funders.length; i++) {
            address founder = funders[i];
            s_addressToAmountFunded[founder] = 0;
        }
        s_funders = new address[](0);
        (bool success, ) = i_owner.call{value: address(this).balance}("");
        require(success);
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getFunders(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getAddressToAmountFunded(
        address funder
    ) public view returns (uint256) {
        return s_addressToAmountFunded[funder];
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return s_priceFeed;
    }
}
