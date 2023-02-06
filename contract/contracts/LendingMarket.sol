// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LoanAgent.sol";

contract LendingMarket {
    struct Lender {
        uint depositAmount;
        uint interest;
    }

    mapping(address => Lender) lenders;
    address[] lenderArray;
    uint sumOfFunds;

    function deposit(uint256 amount) public {
        lenders[msg.sender].depositAmount += amount;
        sumOfFunds += amount;
        if (firstDeposit(msg.sender)) {
            lenderArray.push(msg.sender);
        }
    }

    function firstDeposit(address) private view returns (bool) {
        for (uint i = 0; i < lenderArray.length; i++) {
            if (lenderArray[i] == msg.sender) {
                return false;
            }
        }
        return true;
    }

    function withdraw(uint _amount) public returns (uint) {
        require(
            (lenders[msg.sender].depositAmount +
                lenders[msg.sender].interest) >= _amount,
            "You can't withdraw over sum of you deposited and interest."
        );

        uint depositAmount = lenders[msg.sender].depositAmount;
        if (_amount > depositAmount) {
            lenders[msg.sender].interest -= (_amount - depositAmount);
            lenders[msg.sender].depositAmount = 0;
        } else {
            lenders[msg.sender].depositAmount -= _amount;
        }

        sumOfFunds -= _amount;

        return _amount;
    }

    function getPL() public view returns (uint depositAmount, uint interest) {
        return (
            lenders[msg.sender].depositAmount,
            lenders[msg.sender].interest
        );
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
        bytes memory loanAgentIdBytes = abi.encodePacked(loanAgentId);
        address loanAgentAddress = bytesToAddress(loanAgentIdBytes);
        LoanAgent loanAgent = new LoanAgent(
            _minerActor,
            _totalAmount,
            _interestRate,
            _loanPeriod
        );
        // @dev Borrower will check to change owner in frontend.
        loanAgent.changeOwner(_minerActor, loanAgentAddress);
    }

    function activate(address _loanAgent) private returns (bool) {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        return loanAgent.activate();
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
        for (uint i = 0; i < lenderArray.length; i++) {
            uint portion = calculateInterest(lenderArray[i]);
            lenders[lenderArray[i]].interest += portion * _amount;
        }
        sumOfFunds += _amount;
    }

    function calculateInterest(address _lender) private view returns (uint) {
        uint totalFunds = lenders[_lender].depositAmount +
            lenders[_lender].interest;
        uint portion = totalFunds / sumOfFunds;
        return portion;
    }

    //@dev Convert address to bytes
    function toBytes(address a) private pure returns (bytes memory) {
        return abi.encodePacked(a);
    }

    //@dev Convert Bytes to address
    function bytesToAddress(
        bytes memory _bys
    ) private pure returns (address addr) {
        assembly {
            addr := mload(add(_bys, 20))
        }
    }
}
