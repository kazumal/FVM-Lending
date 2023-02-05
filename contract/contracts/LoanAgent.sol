// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./library/MinerAPI.sol";
import "./library/SendAPI.sol";

contract LoanAgent is MinerAPI, SendAPI {
    address public owner;

    struct Loan {
        address borrower;
        uint256 totalAmount;
        uint256 remainingLoanAmount;
        uint256 interestRate;
        uint256 loanPeriod;
        uint256 nextPaymentDate;
        uint256 amountExpected;
    }

    Loan loan;

    constructor(
        address _minerActor,
        uint _totalAmount,
        uint _interestRate,
        uint _loanPeriod
    ) public {
        owner = msg.sender;
        changeOwner(_minerActor, address(this));
        loan = Loan({
            borrower: _minerActor,
            totalAmount: _totalAmount,
            remainingLoanAmount: _totalAmount,
            interestRate: _interestRate,
            loanPeriod: _loanPeriod,
            nextPaymentDate: 0,
            amountExpected: 0
        });
    }

    modifier isOwnerChanged() {
        require(
            loanAgent.getMinerOwner(address(this)) == address(this),
            "Loan agent ownership transfer failed."
        );
        require(
            loanAgent.getBeneficiaryAddress(address(this)) == address(this),
            "Change of beneficiary failed."
        );
        _;
    }

    function changeOwner(bytes memory target, address newOwner) public {
        require(msg.sender == owner, "Only owner can change the owner address");
        MinerAPI.changeOwnerAddress(target, newOwner.toBytes());
    }

    function changeBeneficiary(bytes memory target) public {
        require(
            msg.sender == owner,
            "Only owner can change the beneficiary address"
        );
        MinerAPI.changeBeneficiary(target, address(this));
    }

    function getMinerOwner(bytes memory target) public view returns (address) {
        return MinerAPI.getOwner(target).owner;
    }

    function isControllingAddress(
        bytes memory target,
        address addr
    ) public view returns (bool) {
        return
            MinerAPI.isControllingAddress(target, addr.toBytes()).controlling;
    }

    function getBeneficiaryAddress(
        _target
    ) public view returns (address _target) {
        MinerAPI.getBeneficiary(_target);
    }

    function getRepaymentSchedule()
        public
        view
        returns (uint nextPaymentDate, uint amountExpected)
    {
        return (loan.nextPaymentDate, loan.amountExpected);
    }

    function receiveRepayment(
        address _loanMarket,
        uint _amount
    ) public returns (uint _amount) {
        require(loan.remainingLoanAmount >= _amount, "Too many reapayment.");
        send(_loanMarket, _amount);
        loan.remainingLoanAmount -= _amount;
    }

    function finishLoan() public returns (address) {
        require(
            loan.remainingLoanAmount <= 0.001,
            "You have remaing loan yet."
        );
        require(
            loan.loanPeriod <= block.timestamp,
            "It is in the loan period."
        );
        changeBeneficiary(address(this), loan.borrower);
        changeOwner(address(this), loan.borrower);
        return (borrower);
    }
}
