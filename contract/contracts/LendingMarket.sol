// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LoanAgent.sol";

contract LendingMarket {
    address public owner;

    constructor() {
        owner = msg.sender;
        index = 0;
    }

    struct Lender {
        uint depositAmount;
        uint interest;
    }

    //@dev Serch specific lenders by using lenders, addressToIndex, and index
    //     lenders[addressToIndex[index]] By doing this  you can reach AddressToLenderInformation
    Lender[] lenders;
    mapping(address => uint) addressToIndex;
    mapping(address => address) minerAddressToLoanAgent;
    uint totalAmount;
    uint index;

    function deposit(uint256 amount) public {
        lenders[addressToIndex[msg.sender]].depositAmount += amount;
        totalAmount += amount;
        if (addressToIndex[msg.sender] == 0) {
            index++;
        }
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
        for (uint i = 0; i < lenders.length; i++) {
            uint depositPropotion = (lenders[i].depositAmount +
                lenders[i].interest) / totalAmount;
            uint interest = _amount * depositPropotion;
            lenders[i].interest += interest;
        }
    }

    function withdraw(uint _amount) public returns (uint) {
        require(
            (lenders[addressToIndex[msg.sender]].depositAmount +
                lenders[addressToIndex[msg.sender]].interest) >= _amount,
            "You can't withdraw over sum of you deposited and interest."
        );

        uint depositAmount = lenders[addressToIndex[msg.sender]].depositAmount;
        if (_amount > depositAmount) {
            lenders[addressToIndex[msg.sender]].interest -= (_amount -
                depositAmount);
            lenders[addressToIndex[msg.sender]].depositAmount = 0;
        } else {
            depositAmount -= _amount;
        }

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
