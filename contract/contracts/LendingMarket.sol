// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LoanAgent.sol";

contract LoanMarket {
    address public owner;

    constructor() {
        owner = msg.sender;
    }

    struct Lender {
        uint depositAmount;
        uint interest;
    }

    mapping(address => Lender) lenders;
    mapping(address => address) minerAddressToLoanAgent;
    uint totalAmount;

    function deposit(uint256 _amount) public payable {
        require(
            msg.sender.transfer(address(this), _amount),
            "Transfer failed."
        );
        lenders[msg.sdenr].depositAmount += msg.value;
        totalAmount += msg.value;
    }

    function createLoanAgent(
        address _minerActor,
        uint _totalAmount,
        uint _interestRate,
        uint _loanPeriod
    ) public {
        bytes32 loanAgentId = keccak256(
            abi.encodePacked(msg.sender, _minerActor, this)
        );
        address loanAgentAddress = address(uint(loanAgentId));
        LoanAgent loanAgent = new LoanAgent(
            _minerActor,
            _totalAmount,
            _interestRate,
            _loanPeriod
        );
        // @dev Borrower will check to change owner in frontend.
        loanAgent.changeOwner(_minerActor, loanAgentAddress);
        minerAddressToLoanAgent[_minerActor] = loanAgentAddress;
    }

    function changeBeneficiary(
        address _loanAgent
    ) public returns (address _loanAgent) {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        require(
            loanAgent.getMinerOwner(_loanAgent) == loanAgentAddress,
            "Loan agent ownership transfer failed."
        );
        loanAgent.changeBeneficiary(_loanAgent);
    }

    function beneficiaryChanged(
        address _loanAgent
    ) public view returns (_loanAgent) {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        require(
            loanAgent.getBeneficiaryAddress(_loanAgent) == _loanAgent,
            "Beneficiary address is not changed."
        );
    }

    function getRepaymentSchedule(
        address _loanAgent
    ) public view returns (uint nextPaymentDate, uint amountExpected) {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        (nextPaymentDate, amountExpected) = loanAgent.getRepaymentSchedule();
    }

    function receiveRepayment(address _loanAgent, uint _amount) public {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        loanAgent.receiveRepayment(address(this), _amount);
        for (uint i = 0; i < lenders.length; i++) {
            uint depositPropotion = (lenders[i].depositAmount +
                lenders[i].interest) / totalAmount;
            uint interest = lenders[i].interest * depositPropotion;
            lenders[i].interest += interest;
        }
    }

    function withdraw(uint _amount) public returns (_amount) {
        require(
            (lenders[msg.sender].depositAmount +
                lenders[msg.sender].interest) >= _amount,
            "You can't withdraw over sum of you deposited and interest."
        );

        uint deposit = lenders[msg.sender].depositAmount;
        if (_amount > deposit) {
            lenders[msg.sender].interest -= (_amount - deposit);
            deposit = 0;
        } else {
            deposit -= _amount;
        }

        require(
            msg.sender.transfer(address(this), _amount),
            "Transfer failed."
        );
    }
}
