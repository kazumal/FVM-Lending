// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Market {
    ERC20 public FIL;
    address public owner;

    constructor(address FILTokenAddress) {
        owner = msg.sender;
        FIL = ERC20(FILTokenAddress);
        index = 0;
    }

    function deposit(uint256 amount) public {
        require(
            FIL.transferFrom(msg.sender, address(this), amount),
            "Deposit failed."
        );
        lenders[addressToIndex[msg.sender]].depositAmount += amount;
        totalAmount += amount;
        if (addressToIndex[msg.sender] == 0) {
            index++;
        }
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

        require(
            FIL.transferFrom(address(this), msg.sender, _amount),
            "Transfer failed."
        );
        return _amount;
    }
}
