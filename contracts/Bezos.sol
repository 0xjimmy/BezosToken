// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./openzeppelin/ERC20.sol";
import "./openzeppelin/Ownable.sol";

contract Bezos is ERC20, Ownable {
    constructor() ERC20("Bezos", "BZS") {
        _mint(msg.sender, 1e27); // 1 T tokens + 18 Decimals
        feeRecipient = msg.sender;
    }

    address public feeRecipient;
    uint256 public initalOwnershipCapTransferCount;
    bool public capStarted;

    function burn(uint256 amount) public {
        _burn(_msgSender(), amount);
    }

    function setFeeRecipient(address newRecipient) public onlyOwner {
        require(newRecipient != address(0));
        feeRecipient = newRecipient;
    }

    function startInitalCap() public onlyOwner {
        capStarted = true;
    }


    /**
     * @dev See {IERC20-transfer}.
     *
     * Requirements:
     *
     * - `recipient` cannot be the zero address.
     * - the caller must have a balance of at least `amount`.
     */
    function transfer(address recipient, uint256 amount) public override returns (bool) {
        _transfer(_msgSender(), recipient, amount);
        return true;
    }
    /**
     * @dev See {IERC20-transferFrom}.
     *
     * Emits an {Approval} event indicating the updated allowance. This is not
     * required by the EIP. See the note at the beginning of {ERC20}.
     *
     * Requirements:
     *
     * - `sender` and `recipient` cannot be the zero address.
     * - `sender` must have a balance of at least `amount`.
     * - the caller must have allowance for ``sender``'s tokens of at least
     * `amount`.
     */
    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        _transfer(sender, recipient, amount);

        uint256 currentAllowance = _allowances[sender][_msgSender()];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(sender, _msgSender(), currentAllowance - amount);

        return true;
    }

    // Override _transfer
    function _transfer(address sender, address recipient, uint256 amount) internal {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");

        _beforeTokenTransfer(sender, recipient, amount);

        uint256 senderBalance = _balances[sender];
        require(senderBalance >= amount, "ERC20: transfer amount exceeds balance");
        
        uint256 fee = (amount * 6) / 100;          // 6% total
        
        if (initalOwnershipCapTransferCount < 300) {
            if (capStarted == true) {
                require((_balances[recipient] + amount) - fee <= 2e18, "Cannot own more than 2 within first 300 tx");
                initalOwnershipCapTransferCount += 1;
            }
        }

        uint256 donationAmount = fee / 3;          // 2% for donation
        uint256 burnAmount = fee - donationAmount; // 4% for burn

        _balances[sender] = senderBalance - amount;
        _totalSupply -= burnAmount;
        _balances[feeRecipient] += donationAmount;
        _balances[recipient] += (amount - fee);

        emit Transfer(sender, address(0), burnAmount);
        emit Transfer(sender, recipient, amount - fee);
        emit Transfer(sender, feeRecipient, donationAmount);
    }
}
