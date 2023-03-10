// SPDX-License-Identifier: MIT
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";
import "@openzeppelin/contracts/utils/EnumerableSet.sol";
import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./CoffeeBeans.sol";


interface IMigratorChef {

    function migrate(IERC20 token) external returns (IERC20);
}


contract MasterChef is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

  
    struct UserInfo {
        uint256 amount;     
        uint256 rewardDebt; 
   
    }

    // Info of each pool.
    struct PoolInfo {
        IERC20 lpToken;          
        uint256 allocPoint;      
        uint256 lastRewardBlock;
        uint256 accCoffeePerShare;
    }

    
    CoffeeBeans public coffee;
 
    address public devaddr;

    uint256 public bonusEndBlock;

    uint256 public coffeePerBlock;

    uint256 public constant BONUS_MULTIPLIER = 10;
 
    IMigratorChef public migrator;

 
    PoolInfo[] public poolInfo;

    mapping (uint256 => mapping (address => UserInfo)) public userInfo;
 
    uint256 public totalAllocPoint = 0;
 
    uint256 public startBlock;

    event Deposit(address indexed user, uint256 indexed pid, uint256 amount);
    event Withdraw(address indexed user, uint256 indexed pid, uint256 amount);
    event EmergencyWithdraw(address indexed user, uint256 indexed pid, uint256 amount);

    constructor(
        CoffeeBeans _coffee,
        address _devaddr,
        uint256 _coffeePerBlock,
        uint256 _startBlock,
        uint256 _bonusEndBlock
    ) public {
        coffee = _coffee;
        devaddr = _devaddr;
        coffeePerBlock = _coffeePerBlock;
        bonusEndBlock = _bonusEndBlock;
        startBlock = _startBlock;
    }

    function poolLength() external view returns (uint256) {
        return poolInfo.length;
    }

 
    function add(uint256 _allocPoint, IERC20 _lpToken, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        uint256 lastRewardBlock = block.number > startBlock ? block.number : startBlock;
        totalAllocPoint = totalAllocPoint.add(_allocPoint);
        poolInfo.push(PoolInfo({
            lpToken: _lpToken,
            allocPoint: _allocPoint,
            lastRewardBlock: lastRewardBlock,
            accCoffeePerShare: 0
        }));
    }


    function set(uint256 _pid, uint256 _allocPoint, bool _withUpdate) public onlyOwner {
        if (_withUpdate) {
            massUpdatePools();
        }
        totalAllocPoint = totalAllocPoint.sub(poolInfo[_pid].allocPoint).add(_allocPoint);
        poolInfo[_pid].allocPoint = _allocPoint;
    }


    function setMigrator(IMigratorChef _migrator) public onlyOwner {
        migrator = _migrator;
    }


    function migrate(uint256 _pid) public {
        require(address(migrator) != address(0), "migrate: no migrator");
        PoolInfo storage pool = poolInfo[_pid];
        IERC20 lpToken = pool.lpToken;
        uint256 bal = lpToken.balanceOf(address(this));
        lpToken.safeApprove(address(migrator), bal);
        IERC20 newLpToken = migrator.migrate(lpToken);
        require(bal == newLpToken.balanceOf(address(this)), "migrate: bad");
        pool.lpToken = newLpToken;
    }


    function getMultiplier(uint256 _from, uint256 _to) public view returns (uint256) {
        if (_to <= bonusEndBlock) {
            return _to.sub(_from).mul(BONUS_MULTIPLIER);
        } else if (_from >= bonusEndBlock) {
            return _to.sub(_from);
        } else {
            return bonusEndBlock.sub(_from).mul(BONUS_MULTIPLIER).add(
                _to.sub(bonusEndBlock)
            );
        }
    }


    function pendingCoffee(uint256 _pid, address _user) external view returns (uint256) {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][_user];
        uint256 accCoffeePerShare = pool.accCoffeePerShare;
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (block.number > pool.lastRewardBlock && lpSupply != 0) {
            uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
            uint256 coffeeReward = multiplier.mul(coffeePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
            accCoffeePerShare = accCoffeePerShare.add(coffeeReward.mul(1e12).div(lpSupply));
        }
        return user.amount.mul(accCoffeePerShare).div(1e12).sub(user.rewardDebt);
    }


    function massUpdatePools() public {
        uint256 length = poolInfo.length;
        for (uint256 pid = 0; pid < length; ++pid) {
            updatePool(pid);
        }
    }

    function updatePool(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        if (block.number <= pool.lastRewardBlock) {
            return;
        }
        uint256 lpSupply = pool.lpToken.balanceOf(address(this));
        if (lpSupply == 0) {
            pool.lastRewardBlock = block.number;
            return;
        }
        uint256 multiplier = getMultiplier(pool.lastRewardBlock, block.number);
        uint256 coffeeReward = multiplier.mul(coffeePerBlock).mul(pool.allocPoint).div(totalAllocPoint);
        coffee.mint(devaddr, coffeeReward.div(10));
        coffee.mint(address(this), coffeeReward);
        pool.accCoffeePerShare = pool.accCoffeePerShare.add(coffeeReward.mul(1e12).div(lpSupply));
        pool.lastRewardBlock = block.number;
    }

 
    function deposit(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        updatePool(_pid);
        if (user.amount > 0) {
            uint256 pending = user.amount.mul(pool.accCoffeePerShare).div(1e12).sub(user.rewardDebt);
            if(pending > 0) {
                safeCoffeeTransfer(msg.sender, pending);
            }
        }
        if(_amount > 0) {
            pool.lpToken.safeTransferFrom(address(msg.sender), address(this), _amount);
            user.amount = user.amount.add(_amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCoffeePerShare).div(1e12);
        emit Deposit(msg.sender, _pid, _amount);
    }

 
    function withdraw(uint256 _pid, uint256 _amount) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        require(user.amount >= _amount, "withdraw: not good");
        updatePool(_pid);
        uint256 pending = user.amount.mul(pool.accCoffeePerShare).div(1e12).sub(user.rewardDebt);
        if(pending > 0) {
            safeCoffeeTransfer(msg.sender, pending);
        }
        if(_amount > 0) {
            user.amount = user.amount.sub(_amount);
            pool.lpToken.safeTransfer(address(msg.sender), _amount);
        }
        user.rewardDebt = user.amount.mul(pool.accCoffeePerShare).div(1e12);
        emit Withdraw(msg.sender, _pid, _amount);
    }

  
    function emergencyWithdraw(uint256 _pid) public {
        PoolInfo storage pool = poolInfo[_pid];
        UserInfo storage user = userInfo[_pid][msg.sender];
        pool.lpToken.safeTransfer(address(msg.sender), user.amount);
        emit EmergencyWithdraw(msg.sender, _pid, user.amount);
        user.amount = 0;
        user.rewardDebt = 0;
    }

 
    function safeCoffeeTransfer(address _to, uint256 _amount) internal {
        uint256 coffeeBal = coffee.balanceOf(address(this));
        if (_amount > coffeeBal) {
            coffee.transfer(_to, coffeeBal);
        } else {
            coffee.transfer(_to, _amount);
        }
    }

    // Update dev address by the previous dev.
    function dev(address _devaddr) public {
        require(msg.sender == devaddr, "dev: wut?");
        devaddr = _devaddr;
    }
}
