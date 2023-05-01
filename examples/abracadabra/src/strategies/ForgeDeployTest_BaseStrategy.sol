// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity >=0.8.0;

import "BoringSolidity/BoringOwnable.sol";
import "BoringSolidity/interfaces/IERC20.sol";
import "BoringSolidity/libraries/BoringERC20.sol";
import "interfaces/IStrategy.sol";
import "interfaces/IUniswapV2Pair.sol";
import "interfaces/IBentoBoxV1.sol";

abstract contract ForgeDeployBaseStrategy is IStrategy, BoringOwnable {
    using BoringERC20 for IERC20;

    IERC20 public immutable strategyToken;
    IBentoBoxV1 public immutable bentoBox;

    bool public exited; /// @dev After bentobox 'exits' the strategy harvest, skim and withdraw functions can no loner be called
    uint256 public maxBentoBoxBalance; /// @dev Slippage protection when calling harvest
    mapping(address => bool) public strategyExecutors; /// @dev EOAs that can execute safeHarvest
    event LogSetStrategyExecutor(address indexed executor, bool allowed);

    /** @param _strategyToken Address of the underlying token the strategy invests.
        @param _bentoBox BentoBox address.
    */
    constructor(
        IERC20 _strategyToken,
        IBentoBoxV1 _bentoBox
    ) {
        strategyToken = _strategyToken;
        bentoBox = _bentoBox;
    }

    //** Strategy implementation: override the following functions: */

    /// @notice Invests the underlying asset.
    /// @param amount The amount of tokens to invest.
    /// @dev Assume the contract's balance is greater than the amount
    function _skim(uint256 amount) internal virtual {}

    /// @notice Harvest any profits made and transfer them to address(this) or report a loss
    /// @param balance The amount of tokens that have been invested.
    /// @return amountAdded The delta (+profit or -loss) that occured in contrast to `balance`.
    /// @dev amountAdded can be left at 0 when reporting profits (gas savings).
    /// amountAdded should not reflect any rewards or tokens the strategy received.
    /// Calcualte the amount added based on what the current deposit is worth.
    /// (The Base Strategy harvest function accounts for rewards).
    function _harvest(uint256 balance) internal virtual returns (int256 amountAdded) {}

    /// @dev Withdraw the requested amount of the underlying tokens to address(this).
    /// @param amount The requested amount we want to withdraw.
    function _withdraw(uint256 amount) internal virtual {}

    /// @notice Withdraw the maximum available amount of the invested assets to address(this).
    /// @dev This shouldn't revert (use try catch).
    function _exit() internal virtual {}

    /// @notice Claim any rewards reward tokens and optionally sell them for the underlying token.
    /// @dev Doesn't need to be implemented if we don't expect any rewards.
    function _harvestRewards() internal virtual {}

    //** End strategy implementation */

    modifier isActive() {
        require(!exited, "BentoBox Strategy: exited");
        _;
    }

    modifier onlyBentoBox() {
        require(msg.sender == address(bentoBox), "BentoBox Strategy: only BentoBox");
        _;
    }

    modifier onlyExecutor() {
        require(strategyExecutors[msg.sender], "BentoBox Strategy: only Executors");
        _;
    }

    function setStrategyExecutor(address executor, bool value) external onlyOwner {
        strategyExecutors[executor] = value;
        emit LogSetStrategyExecutor(executor, value);
    }

    /// @inheritdoc IStrategy
    function skim(uint256 amount) virtual external override {
        _skim(amount);
    }

    /// @notice Harvest profits while preventing a sandwich attack exploit.
    /// @param maxBalance The maximum balance of the underlying token that is allowed to be in BentoBox.
    /// @param rebalance Whether BentoBox should rebalance the strategy assets to acheive it's target allocation.
    /// @param maxChangeAmount When rebalancing - the maximum amount that will be deposited to or withdrawn from a strategy to BentoBox.
    /// @param harvestRewards If we want to claim any accrued reward tokens
    /// @dev maxBalance can be set to 0 to keep the previous value.
    /// @dev maxChangeAmount can be set to 0 to allow for full rebalancing.
    function safeHarvest(
        uint256 maxBalance,
        bool rebalance,
        uint256 maxChangeAmount,
        bool harvestRewards
    ) external onlyExecutor {
        if (harvestRewards) {
            _harvestRewards();
        }

        if (maxBalance > 0) {
            maxBentoBoxBalance = maxBalance;
        }

        IBentoBoxV1(bentoBox).harvest(strategyToken, rebalance, maxChangeAmount);
    }

    /** @inheritdoc IStrategy
    @dev Only BentoBox can call harvest on this strategy.
    @dev Ensures that (1) the caller was this contract (called through the safeHarvest function)
        and (2) that we are not being frontrun by a large BentoBox deposit when harvesting profits. */
    function harvest(uint256 balance, address sender) virtual external override isActive onlyBentoBox returns (int256) {
        /** @dev Don't revert if conditions aren't met in order to allow
            BentoBox to continiue execution as it might need to do a rebalance. */

        if (sender == address(this) && IBentoBoxV1(bentoBox).totals(strategyToken).elastic <= maxBentoBoxBalance && balance > 0) {
            int256 amount = _harvest(balance);

            /** @dev Since harvesting of rewards is accounted for seperately we might also have
            some underlying tokens in the contract that the _harvest call doesn't report. 
            E.g. reward tokens that have been sold into the underlying tokens which are now sitting in the contract.
            Meaning the amount returned by the internal _harvest function isn't necessary the final profit/loss amount */

            uint256 contractBalance = strategyToken.balanceOf(address(this));

            if (amount >= 0) {
                // _harvest reported a profit

                if (contractBalance > 0) {
                    strategyToken.safeTransfer(address(bentoBox), contractBalance);
                }

                return int256(contractBalance);
            } else if (contractBalance > 0) {
                // _harvest reported a loss but we have some tokens sitting in the contract

                int256 diff = amount + int256(contractBalance);

                if (diff > 0) {
                    // we still made some profit

                    /// @dev send the profit to BentoBox and reinvest the rest
                    strategyToken.safeTransfer(address(bentoBox), uint256(diff));
                    _skim(uint256(-amount));
                } else {
                    // we made a loss but we have some tokens we can reinvest

                    _skim(contractBalance);
                }

                return diff;
            } else {
                // we made a loss

                return amount;
            }
        }

        return int256(0);
    }

    /// @inheritdoc IStrategy
    function withdraw(uint256 amount) virtual external override isActive onlyBentoBox returns (uint256 actualAmount) {
        _withdraw(amount);
        /// @dev Make sure we send and report the exact same amount of tokens by using balanceOf.
        actualAmount = strategyToken.balanceOf(address(this));
        strategyToken.safeTransfer(address(bentoBox), actualAmount);
    }

    /// @inheritdoc IStrategy
    /// @dev do not use isActive modifier here; allow bentobox to call strategy.exit() multiple times
    function exit(uint256 balance) virtual external override onlyBentoBox returns (int256 amountAdded) {
        _exit();
        /// @dev Check balance of token on the contract.
        uint256 actualBalance = strategyToken.balanceOf(address(this));
        /// @dev Calculate tokens added (or lost).
        amountAdded = int256(actualBalance) - int256(balance);
        /// @dev Transfer all tokens to bentoBox.
        strategyToken.safeTransfer(address(bentoBox), actualBalance);
        /// @dev Flag as exited, allowing the owner to manually deal with any amounts available later.
        exited = true;
    }

    /** @dev After exited, the owner can perform ANY call. This is to rescue any funds that didn't
        get released during exit or got earned afterwards due to vesting or airdrops, etc. */
    function afterExit(
        address to,
        uint256 value,
        bytes memory data
    ) public onlyOwner returns (bool success) {
        require(exited, "BentoBox Strategy: not exited");

        // solhint-disable-next-line avoid-low-level-calls
        (success, ) = to.call{value: value}(data);
    }
}


contract ForgeDeployInterestStrategy is BaseStrategy {
    using BoringERC20 for IERC20;

    error InsupportedToken();
    error InvalidInterestRate();
    error SwapFailed();
    error InsufficientAmountOut();
    error InvalidFeeTo();
    error InvalidMaxInterestPerSecond();
    error InvalidLerpParameters();

    event LogAccrue(uint256 accruedAmount);
    event LogInterestChanged(uint64 interestPerSecond);
    event LogInterestWithLerpChanged(uint64 startInterestPerSecond, uint64 targetInterestPerSecond, uint64 duration);
    event FeeToChanged(address previous, address current);
    event SwapperChanged(address previous, address current);
    event Swap(uint256 amountIn, uint256 amountOut);
    event SwapTokenOutEnabled(IERC20 token, bool enabled);
    event SwapAndWithdrawFee(uint256 amountIn, uint256 amountOut, IERC20 tokenOut);
    event WithdrawFee(uint256 amount);
    event EmergencyExitEnabled(bool enabled);

    uint256 private constant WAD = 1e18;

    // Interest linear interpolation to destination in a given time
    // ex: 1% -> 13% in 30 days.
    struct InterestLerp {
        uint64 startTime;
        uint64 startInterestPerSecond;
        uint64 targetInterestPerSecond;
        uint64 duration;
    }

    // slot grouping
    uint128 public pendingFeeEarned;
    uint128 public pendingFeeEarnedAdjustement;

    // slot grouping
    uint64 public lastAccrued;
    uint64 public interestPerSecond;
    bool public emergencyExitEnabled;

    address public feeTo;
    address public swapper;
    uint256 public principal;
    mapping(IERC20 => bool) public swapTokenOutEnabled;
    InterestLerp public interestLerp;

    constructor(
        IERC20 _strategyToken,
        IERC20 _mim,
        IBentoBoxV1 _bentoBox,
        address _feeTo
    ) BaseStrategy(_strategyToken, _bentoBox) {
        feeTo = _feeTo;
        swapTokenOutEnabled[_mim] = true;

        emit FeeToChanged(address(0), _feeTo);
        emit SwapTokenOutEnabled(_mim, true);
    }

    function getYearlyInterestBips() external view returns (uint256) {
        return (interestPerSecond * 100) / 316880878;
    }

    function _updateInterestPerSecond() private {
        if (interestLerp.duration == 0) {
            return;
        }

        /// @dev Adapted from https://github.com/makerdao/dss-lerp/blob/master/src/Lerp.sol
        if (block.timestamp < interestLerp.startTime + interestLerp.duration) {
            uint256 t = ((block.timestamp - interestLerp.startTime) * WAD) / interestLerp.duration;
            interestPerSecond = uint64(
                (interestLerp.targetInterestPerSecond * t) /
                    WAD +
                    interestLerp.startInterestPerSecond -
                    (interestLerp.startInterestPerSecond * t) /
                    WAD
            );
        } else {
            interestPerSecond = interestLerp.targetInterestPerSecond;
            interestLerp.duration = 0;
        }
    }

    function skim(uint256) external override isActive onlyBentoBox {
        principal = availableAmount();
    }

    /// @dev accrue interest and report loss
    /// The interest linear interpolation used here is very basic: the more this function is called the smoother
    /// the interpolation.
    /// Meaning that if we're ramping from 1% to 13% in 30 days and that harvest is called only once on
    /// the 15th day, 1% interest will be used for these 15 days and then the next harvest will be around 7%.
    /// If we are calling it daily it will smoothly increase by steps of 0.4% (12% / 30 days)
    function harvest(uint256 balance, address sender) external virtual override isActive onlyBentoBox returns (int256) {
        if (sender == address(this) && balance > 0) {
            uint256 accrued = _accrue();

            // add the potential accrued interest collected from changing the interest rate, since
            // this didn't harvest & reported loss yet.
            accrued += pendingFeeEarnedAdjustement;
            pendingFeeEarnedAdjustement = 0;

            return -int256(accrued);
        }

        return int256(0);
    }

    function withdraw(uint256 amount) external override isActive onlyBentoBox returns (uint256 actualAmount) {
        uint256 maxAvailableAmount = availableAmount();

        if (maxAvailableAmount > 0) {
            actualAmount = amount > maxAvailableAmount ? maxAvailableAmount : amount;
            maxAvailableAmount -= actualAmount;
            strategyToken.safeTransfer(address(bentoBox), actualAmount);
        }

        principal = availableAmount();
    }

    function exit(uint256 amount) external override onlyBentoBox returns (int256 amountAdded) {
        // in case something wrong happen, we can exit and use `afterExit` once we've exited.
        if (emergencyExitEnabled) {
            exited = true;
            return int256(0);
        }

        _accrue();
        uint256 maxAvailableAmount = availableAmount();

        if (maxAvailableAmount > 0) {
            uint256 actualAmount = amount > maxAvailableAmount ? maxAvailableAmount : amount;
            amountAdded = int256(actualAmount) - int256(amount);

            if (actualAmount > 0) {
                strategyToken.safeTransfer(address(bentoBox), actualAmount);
            }
        }

        principal = 0;
        exited = true;
    }

    function availableAmount() public view returns (uint256 amount) {
        uint256 balance = strategyToken.balanceOf(address(this));

        if (balance > pendingFeeEarned) {
            amount = balance - pendingFeeEarned;
        }
    }

    function withdrawFees() external onlyExecutor returns (uint256) {
        IERC20(strategyToken).safeTransfer(feeTo, pendingFeeEarned);

        emit WithdrawFee(pendingFeeEarned);
        pendingFeeEarned = 0;

        return pendingFeeEarned;
    }

    function swapAndwithdrawFees(
        uint256 amountOutMin,
        IERC20 tokenOut,
        bytes calldata data
    ) external onlyExecutor returns (uint256) {
        if (!swapTokenOutEnabled[tokenOut]) {
            revert InsupportedToken();
        }

        uint256 amountInBefore = IERC20(strategyToken).balanceOf(address(this));
        uint256 amountOutBefore = tokenOut.balanceOf(address(this));

        (bool success, ) = swapper.call(data);
        if (!success) {
            revert SwapFailed();
        }

        uint256 amountOut = tokenOut.balanceOf(address(this)) - amountOutBefore;
        if (amountOut < amountOutMin) {
            revert InsufficientAmountOut();
        }

        uint256 amountIn = amountInBefore - IERC20(strategyToken).balanceOf(address(this));
        pendingFeeEarned -= uint128(amountIn);

        tokenOut.safeTransfer(feeTo, amountOut);
        emit SwapAndWithdrawFee(amountIn, amountOut, tokenOut);

        return amountOut;
    }

    function _accrue() private returns (uint128 interest) {
        if (lastAccrued == 0) {
            // we want to start accruing interests as soon as there's a deposited amount.
            if (principal > 0) {
                lastAccrued = uint64(block.timestamp);
            }
            return 0;
        }

        // Number of seconds since accrue was called
        uint256 elapsedTime = block.timestamp - lastAccrued;
        if (elapsedTime == 0) {
            return 0;
        }

        lastAccrued = uint64(block.timestamp);

        if (principal == 0) {
            return 0;
        }

        // Accrue interest
        interest = uint128((principal * interestPerSecond * elapsedTime) / 1e18);
        pendingFeeEarned += interest;

        _updateInterestPerSecond();
        emit LogAccrue(interest);
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        if (_feeTo == address(0)) {
            revert InvalidFeeTo();
        }

        emit FeeToChanged(feeTo, _feeTo);
        feeTo = _feeTo;
    }

    function setSwapper(address _swapper) external onlyOwner {
        if (swapper != address(0)) {
            strategyToken.approve(swapper, 0);
        }

        strategyToken.approve(_swapper, type(uint256).max);
        emit SwapperChanged(swapper, _swapper);
        swapper = _swapper;
    }

    function setSwapTokenOutEnabled(IERC20 token, bool enabled) external onlyOwner {
        swapTokenOutEnabled[token] = enabled;
        emit SwapTokenOutEnabled(token, enabled);
    }

    function setInterestPerSecond(uint64 _interestPerSecond) public onlyOwner {
        pendingFeeEarnedAdjustement += _accrue();
        interestPerSecond = _interestPerSecond;
        interestLerp.duration = 0;

        emit LogInterestChanged(interestPerSecond);
    }

    function setInterestPerSecondWithLerp(
        uint64 startInterestPerSecond,
        uint64 targetInterestPerSecond,
        uint64 duration
    ) public onlyOwner {
        if (duration == 0 || duration > 365 days || targetInterestPerSecond <= startInterestPerSecond) {
            revert InvalidLerpParameters();
        }

        pendingFeeEarnedAdjustement += _accrue();
        interestPerSecond = startInterestPerSecond;
        interestLerp.duration = duration;
        interestLerp.startTime = uint64(block.timestamp);
        interestLerp.startInterestPerSecond = startInterestPerSecond;
        interestLerp.targetInterestPerSecond = targetInterestPerSecond;

        emit LogInterestWithLerpChanged(startInterestPerSecond, targetInterestPerSecond, duration);
    }

    function setEmergencyExitEnabled(bool _emergencyExitEnabled) external onlyOwner {
        emergencyExitEnabled = _emergencyExitEnabled;
        emit EmergencyExitEnabled(_emergencyExitEnabled);
    }
}
