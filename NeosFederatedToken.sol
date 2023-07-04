// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NeosFederatedToken is ERC20, ReentrancyGuard {
    using SafeMath for uint256;

    struct StakingInfo {
        uint256 amount;
        uint256 lastStakedTime;
    }

    mapping(address => StakingInfo) public stakes;
    uint256 public stakingPeriod = 30 days;
    uint256 public rewardRate = 10;  // Reward rate in percentage

    constructor(uint256 initialSupply) ERC20("Neos Federated Token", "NFT") {
        _mint(msg.sender, initialSupply);
    }

    function stakeTokens(uint256 _amount) public nonReentrant {
        require(stakes[msg.sender].amount == 0, "Already staked. Unstake first.");

        _burn(msg.sender, _amount);
        stakes[msg.sender].amount = stakes[msg.sender].amount.add(_amount);
        stakes[msg.sender].lastStakedTime = block.timestamp;
    }

    function unstakeTokens() public nonReentrant {
        StakingInfo storage staker = stakes[msg.sender];
        require(block.timestamp >= staker.lastStakedTime.add(stakingPeriod), "Staking period not yet completed.");

        uint256 reward = calculateReward(staker.amount, staker.lastStakedTime, rewardRate);
        uint256 payout = staker.amount.add(reward);

        staker.amount = 0;
        staker.lastStakedTime = 0;

        _mint(msg.sender, payout);
    }

    function calculateReward(uint256 _amount, uint256 _stakeTime, uint256 _rewardRate) private view returns(uint256) {
        uint256 timeStaked = block.timestamp.sub(_stakeTime);
        uint256 reward = _amount.mul(_rewardRate).mul(timeStaked).div(365 days).div(100);
        return reward;
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        require(msg.sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(balanceOf(msg.sender) >= amount, "ERC20: transfer amount exceeds balance");

        _transfer(msg.sender, recipient, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public override returns (bool) {
        require(msg.sender != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address sender, address recipient, uint256 amount) public override returns (bool) {
        require(sender != address(0), "ERC20: transfer from the zero address");
        require(recipient != address(0), "ERC20: transfer to the zero address");
        require(amount <= balanceOf(sender), "ERC20: transfer amount exceeds balance");
        require(amount <= allowance(sender, msg.sender), "ERC20: transfer amount exceeds allowance");

        _transfer(sender, recipient, amount);
        _approve(sender, msg.sender, allowance(sender, msg.sender).sub(amount));
        return true;
    }
}
