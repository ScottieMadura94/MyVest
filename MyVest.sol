// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TokenVesting {
    address public beneficiary;
    uint256 public cliff;
    uint256 public start;
    uint256 public duration;
    uint256 public released;
    bool public revocable;
    bool public revoked;

    IERC20 public token;

    event TokensReleased(uint256 amount);
    event VestingRevoked();

    modifier onlyBeneficiary() {
        require(msg.sender == beneficiary, "Only the beneficiary can call this function");
        _;
    }

    constructor(
        address _beneficiary,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        bool _revocable,
        address _token
    ) {
        require(_beneficiary != address(0), "Invalid beneficiary address");
        require(_cliff <= _duration, "Cliff period must be less than or equal to duration");

        beneficiary = _beneficiary;
        cliff = _start + _cliff;
        start = _start;
        duration = _duration;
        revocable = _revocable;
        token = IERC20(_token);
    }
function release() public onlyBeneficiary {
        require(!revoked, "Vesting is revoked");
        require(block.timestamp >= cliff, "Vesting cliff not reached");
        require(released == 0, "Tokens have already been released");

        uint256 vested = calculateVestedAmount();
        require(vested > 0, "No tokens are vested");

        released = vested;
        require(token.transfer(beneficiary, vested), "Token transfer failed");

        emit TokensReleased(vested);
    }
function calculateVestedAmount() public view returns (uint256) {
        if (block.timestamp < cliff) {
            return 0;
        } else if (block.timestamp >= start + duration || revoked) {
            return token.balanceOf(address(this));
        } else {
            return (token.balanceOf(address(this)) * (block.timestamp - start)) / duration;
        }
    }

function revoke() public onlyBeneficiary {
        require(revocable, "Vesting is not revocable");
        require(!revoked, "Vesting already revoked");

        uint256 vested = calculateVestedAmount();
        require(vested > 0, "No tokens are vested");

        revoked = true;
        require(token.transfer(beneficiary, vested), "Token transfer failed");

        emit VestingRevoked();
    }

function remainingBalance() public view returns (uint256) {
        return token.balanceOf(address(this));
    }

    function getVestingDetails() public view returns (uint256, uint256, uint256, bool, bool) {
        return (cliff, start, duration, revocable, revoked);
    }

}
