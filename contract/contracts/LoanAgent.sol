// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./library/types/MinerTypes.sol";
import "./library/types/CommonTypes.sol";
import "./library/cbor/BigIntCbor.sol";
import "./library/MinerAPI.sol";
import "./library/SendAPI.sol";

contract LoanAgent {
    address public owner;
    struct Loan {
        address borrower;
        uint256 totalAmount;
        uint256 remainingLoanAmount;
        uint256 interestRate;
        uint256 loanPeriod;
        uint256 nextPaymentDate;
        uint256 amountExpected;
        bool activated;
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
            amountExpected: 0,
            activated: false
        });
    }

    modifier isOwnerChanged() {
        require(
            getMinerOwner(address(this)) == address(this),
            "Loan agent ownership transfer failed."
        );
        require(
            getBeneficiaryAddress(address(this)) == address(this),
            "Change of beneficiary failed."
        );
        _;
    }

    function changeOwner(address _target, address newOwner) public {
        require(msg.sender == owner, "Only owner can change the owner address");
        MinerAPI.changeOwnerAddress(toBytes(_target), toBytes(newOwner));
    }

    function changeBeneficiary(
        address _target,
        address _newBeneficiary,
        uint _newQuota,
        uint64 _newExpiration
    ) public {
        require(
            msg.sender == owner,
            "Only owner can change the beneficiary address"
        );
        MinerTypes.ChangeBeneficiaryParams memory changeBeneficiaryParams;
        changeBeneficiaryParams = MinerTypes.ChangeBeneficiaryParams({
            new_beneficiary: toBytes(_newBeneficiary),
            new_quota: makeNewQuota(_newQuota),
            new_expiration: _newExpiration
        });
        MinerAPI.changeBeneficiary(toBytes(_target), changeBeneficiaryParams);
    }

    function makeNewQuota(uint _val) public pure returns (BigInt memory) {
        BigInt memory bigInt;
        bytes memory val = abi.encodePacked(_val);
        bigInt = BigInt({val: val, neg: false});
        return bigInt;
    }

    function getMinerOwner(address _target) public returns (address) {
        bytes memory value = MinerAPI.getOwner(toBytes(_target)).owner;
        return bytesToAddress(value);
    }

    function isControllingAddress(
        address _target,
        address _addr
    ) public returns (bool) {
        return
            MinerAPI
                .isControllingAddress(toBytes(_target), toBytes(_addr))
                .is_controlling;
    }

    function getBeneficiaryAddress(address _target) public returns (address) {
        address value = bytesToAddress(
            MinerAPI.getBeneficiary(toBytes(_target)).active.beneficiary
        );
        return value;
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
    ) public returns (uint) {
        require(loan.remainingLoanAmount >= _amount, "Too many reapayment.");
        SendAPI.send(toBytes(_loanMarket), _amount);
        loan.remainingLoanAmount -= _amount;
        return (_amount);
    }

    function activate() public returns (bool) {
        require(
            getBeneficiaryAddress(address(this)) == address(this),
            "Beneficiary is not changed."
        );
        loan.activated = true;
        return (true);
    }

    function finishLoan() public returns (address) {
        require(loan.remainingLoanAmount <= 0, "You have remaing loan yet.");
        require(
            loan.loanPeriod <= block.timestamp,
            "It is in the loan period."
        );

        // @dev Hardcording 3rd & 4th argment,NewQuota and newexpiration,
        changeBeneficiary(address(this), loan.borrower, 10000, 10000);
        changeOwner(address(this), loan.borrower);
        return (loan.borrower);
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
