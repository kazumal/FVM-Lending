// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LoanAgent.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract LoanMarket {
    ERC20 public FIL;
    address public owner;

    constructor(address FILTokenAddress) {
        owner = msg.sender;
        FIL = ERC20(FILTokenAddress);
    }

    struct Lender {
        uint depositAmount;
        uint interest;
    }

    mapping(address => Lender) lenders;
    mapping(address => address) minerAddressToLoanAgent;
    uint totalAmount;

    function deposit(uint256 amount) public {
        require(
            FIL.transferFrom(msg.sender, address(this), amount),
            "Deposit failed."
        );
        lenders[msg.sender].depositAmount += amount;
        totalAmount += amount;
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
        minerAddressToLoanAgent[_minerActor] = loanAgentAddress;
    }

    function changeBeneficiary(address _loanAgent) public returns (address) {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        require(
            loanAgent.getMinerOwner(_loanAgent) == _loanAgent,
            "Loan agent ownership transfer failed."
        );
        loanAgent.changeBeneficiary(_loanAgent, address(this), 10000, 10000);
        return (_loanAgent);
    }

    function beneficiaryChanged(address _loanAgent) public returns (address) {
        LoanAgent loanAgent = LoanAgent(_loanAgent);
        require(
            loanAgent.getBeneficiaryAddress(_loanAgent) == _loanAgent,
            "Beneficiary address is not changed."
        );
        return _loanAgent;
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
            depositAmount -= _amount;
        }

        require(
            FIL.transferFrom(address(this), msg.sender, _amount),
            "Transfer failed."
        );
        return _amount;
    }

    //@dev Convert address to bytes
    function toBytes(address a) public pure returns (bytes memory) {
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
