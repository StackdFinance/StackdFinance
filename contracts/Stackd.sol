pragma solidity ^0.8.10;

// SPDX-License-Identifier: UNLICENSED

library SafeMath {
    function tryAdd(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        uint256 c = a + b;
        if (c < a) return (false, 0);
        return (true, c);
    }
    }

    function trySub(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b > a) return (false, 0);
        return (true, a - b);
    }
    }

    function tryMul(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) return (true, 0);
        uint256 c = a * b;
        if (c / a != b) return (false, 0);
        return (true, c);
    }
    }

    function tryDiv(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a / b);
    }
    }

    function tryMod(uint256 a, uint256 b)
    internal
    pure
    returns (bool, uint256)
    {
    unchecked {
        if (b == 0) return (false, 0);
        return (true, a % b);
    }
    }

    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return a / b;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return a % b;
    }

    function sub(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b <= a, errorMessage);
        return a - b;
    }
    }

    function div(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a / b;
    }
    }

    function mod(
        uint256 a,
        uint256 b,
        string memory errorMessage
    ) internal pure returns (uint256) {
    unchecked {
        require(b > 0, errorMessage);
        return a % b;
    }
    }
}

interface IUniswapV2Factory {
    function createPair(address tokenA, address tokenB)
    external
    returns (address pair);
}

interface IDexRouter {
    function factory() external pure returns (address);

    function WETH() external pure returns (address);

    function addLiquidityETH(
        address token,
        uint256 amountTokenDesired,
        uint256 amountTokenMin,
        uint256 amountETHMin,
        address to,
        uint256 deadline
    )
    external
    payable
    returns (
        uint256 amountToken,
        uint256 amountETH,
        uint256 liquidity
    );

    function swapExactETHForTokensSupportingFeeOnTransferTokens(
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external payable;

    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint256 amountIn,
        uint256 amountOutMin,
        address[] calldata path,
        address to,
        uint256 deadline
    ) external;
}

interface IERC20Extended {
    function totalSupply() external view returns (uint256);

    function decimals() external view returns (uint8);

    function symbol() external view returns (string memory);

    function name() external view returns (string memory);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
    external
    returns (bool);

    function allowance(address _owner, address spender)
    external
    view
    returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

abstract contract Auth {
    address internal owner;
    mapping(address => bool) internal authorizations;

    constructor(address _owner) {
        owner = _owner;
        authorizations[_owner] = true;
    }

    modifier onlyOwner() {
        require(isOwner(msg.sender), "!OWNER");
        _;
    }

    modifier authorized() {
        require(isAuthorized(msg.sender), "!AUTHORIZED");
        _;
    }

    function authorize(address adr) public onlyOwner {
        authorizations[adr] = true;
    }

    function unauthorize(address adr) public onlyOwner {
        authorizations[adr] = false;
    }

    function isOwner(address account) public view returns (bool) {
        return account == owner;
    }

    function isAuthorized(address adr) public view returns (bool) {
        return authorizations[adr];
    }

    function transferOwnership(address payable adr) public onlyOwner {
        owner = adr;
        authorizations[adr] = true;
        emit OwnershipTransferred(adr);
    }

    event OwnershipTransferred(address owner);
}

contract LotteryManager {
    using SafeMath for uint;

    address public _token;
    uint public minimumHolding;
    uint public totalShares;

    address[] public shareholders;
    mapping(address => uint) public shareholderIndexes;
    mapping(address => uint) public shares;

    // Lottery
    mapping(address => bool) public excludedFromLottery;
    mapping(uint => address[]) public winners;
    mapping(uint => bool) public drawingCompleted;
    uint public minHolding;
    uint public iteration;
    uint public numWinners;
    uint public lastDrawing;
    uint public timeBetweenDrawings;

    constructor(address router_) {
        _token = msg.sender;
    }

    modifier onlyToken() {
        require(msg.sender == _token);
        _;
    }

    function setExcludedFromLottery(address user, bool value) external onlyToken {
        excludedFromLottery[user] = value;
    }

    function setMinHolding(uint newMin) external onlyToken {
        minHolding = newMin;
    }

    function setTimeBetweenDrawings(uint newTime) external onlyToken {
        timeBetweenDrawings = newTime;
    }

    function setNumWinners(uint number) external onlyToken {
        number = number;
    }


    function setShare(address shareholder, uint256 amount)
    external
    onlyToken
    {
        if (amount > minimumHolding && shares[shareholder] == 0) {
            addShareholder(shareholder);
        } else if (amount == 0 && shares[shareholder] > minimumHolding) {
            removeShareholder(shareholder);
        }

        totalShares = totalShares.sub(shares[shareholder]).add(amount);
        shares[shareholder] = amount;
    }

    function addShareholder(address shareholder) internal {
        shareholderIndexes[shareholder] = shareholders.length;
        shareholders.push(shareholder);
    }

    function removeShareholder(address shareholder) internal {
        shareholders[shareholderIndexes[shareholder]] = shareholders[
        shareholders.length - 1
        ];
        shareholderIndexes[
        shareholders[shareholders.length - 1]
        ] = shareholderIndexes[shareholder];
        shareholders.pop();
    }

    // Lottery Functions
    function random() internal view returns (uint) {
        return uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % shareholders.length;
    }


    function distributeWinnings() internal {
        uint total = address(this).balance;
        uint denominator = 0;
        for (uint i = 0; i < winners[iteration - 1].length; i++) {
            denominator += shares[winners[iteration - 1][i]];
        }
        for (uint i = 0; i < winners[iteration - 1].length; i++) {
            uint percentageTotal = (shares[winners[iteration - 1][i]] * 10000) / denominator; // percentage of pot in basis points
            uint owed = (total * percentageTotal) / 10000;
            payable(winners[iteration - 1][i]).transfer(owed);
        }
    }

    function pickWinners() external onlyToken {
        require(!drawingCompleted[iteration], "This drawing has already concluded");
        require(block.timestamp > lastDrawing + timeBetweenDrawings, "You cant pick winners yet");

        for (uint i = 0; i < numWinners; i++) {
            uint winner = random();
            winners[iteration][i] = shareholders[winner];
        }
        iteration += 1;
        lastDrawing = block.timestamp;
        distributeWinnings();
    }

}




contract Jackpot is IERC20Extended, Auth {
    using SafeMath for uint256;

    string private constant _name = "Jackpot Token";
    string private constant _symbol = "JACK";
    uint8 private constant _decimals = 18;
    uint256 private constant _totalSupply =
    1000000 * 10**_decimals;

    address public constant DEAD = address(0xdead);
    address public constant ZERO = address(0);
    address public constant ROUTER = 0x10ED43C718714eb63d5aA57B78B54704E256024E;
    address public pair;
    address public autoLiquidityReceiver = 0x393B9D84495FdAf7098dd623260Af93274F4Bcb1; // address to receive LP tokens from liquidity add from fee

    // fees info
    uint256 public liquidityFee = 200;
    uint256 public lotteryFee = 1000;
    uint256 public totalFee = 1200;
    uint256 public feeDenominator = 10000;
    uint256 public sellMultiplier = 1;

    uint256 public swapThreshold = _totalSupply / 20000;
    uint256 public startBlock;
    uint256 private deadBlocks;
    uint256 private sniperFee;

    bool public sellMultiplierEnabled;
    bool public swapEnabled = true;
    bool public tradingEnabled;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => bool) public isFeeExempt;
    mapping(address => bool) public canTransferBeforeTradingIsEnabled;

    IDexRouter public router;
    LotteryManager public lottery;

    event AutoLiquify(uint256 amountBNB, uint256 amountBOG);

    bool inSwap;
    modifier swapping() {
        inSwap = true;
        _;
        inSwap = false;
    }


    constructor(address _lottery)
    payable
    Auth(msg.sender)
    {
        lottery = new LotteryManager(ROUTER);
        router = IDexRouter(ROUTER);
        pair = IUniswapV2Factory(router.factory()).createPair(
            address(this),
            router.WETH()
        );
        isFeeExempt[msg.sender] = true;
        isFeeExempt[autoLiquidityReceiver] = true;

        setExcludedFromLottery(pair, true);
        setExcludedFromLottery(msg.sender, true);

        canTransferBeforeTradingIsEnabled[msg.sender] = true;

        _allowances[address(this)][address(router)] = _totalSupply;
        _allowances[address(this)][address(pair)] = _totalSupply;

        _balances[msg.sender] = _totalSupply;
        emit Transfer(address(0), msg.sender, _totalSupply);
    }

    receive() external payable {}


    // Anti-Bot
    function enableTrading(
        uint _deadBlocks,
        uint _sniperFee
    )
    external
    authorized
    {
        tradingEnabled = true;
        startBlock = block.number;
        deadBlocks = _deadBlocks;
        sniperFee = _sniperFee; // in basis points, base 10000
    }


    // Standard ERC-20 Functions
    function totalSupply()
    external
    pure
    override
    returns (uint256)
    {
        return _totalSupply;
    }


    function decimals()
    external
    pure
    override
    returns (uint8)
    {
        return _decimals;
    }


    function symbol()
    external
    pure
    override
    returns (string memory)
    {
        return _symbol;
    }


    function name()
    external
    pure
    override
    returns (string memory)
    {
        return _name;
    }


    function balanceOf(
        address account
    )
    public
    view
    override
    returns (uint256)
    {
        return _balances[account];
    }


    function allowance(
        address holder,
        address spender
    )
    external
    view
    override
    returns (uint256)
    {
        return _allowances[holder][spender];
    }


    function approve(
        address spender,
        uint256 amount
    )
    public
    override
    returns (bool)
    {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }


    function approveMax(
        address spender
    )
    external
    returns (bool)
    {
        return approve(spender, _totalSupply);
    }


    function transfer(
        address recipient,
        uint256 amount
    )
    external
    override
    returns (bool)
    {
        return _transferFrom(msg.sender, recipient, amount);
    }


    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
    external
    override
    returns (bool)
    {
        if (_allowances[sender][msg.sender] != _totalSupply) {
            _allowances[sender][msg.sender] = _allowances[sender][msg.sender]
            .sub(amount, "Insufficient Allowance");
        }

        return _transferFrom(sender, recipient, amount);
    }


    function _transferFrom(
        address sender,
        address recipient,
        uint256 amount
    )
    internal
    returns (bool)
    {

        if (!tradingEnabled) {
            require(canTransferBeforeTradingIsEnabled[sender], "You cannot transfer before trading is enabled");
        }

        if (inSwap) {
            return _basicTransfer(sender, recipient, amount);
        }

        if (shouldSwapBack()) {
            swapBack(swapThreshold);
        }

        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );

        uint256 amountReceived;
        if (block.number < startBlock.add(deadBlocks)) {
            amountReceived = shouldTakeFee(sender, recipient)
            ? takeSniperFee(sender, amount)
            : amount;
        }
        else {
            amountReceived = shouldTakeFee(sender, recipient)
            ? takeFee(sender, recipient, amount)
            : amount;
        }

        // TODO: Handle Lottery Stuff Here
        if (!lottery.excludedFromLottery(sender)) {
            try lottery.setShare(sender, _balances[sender]) {} catch {}
        }

        _balances[recipient] = _balances[recipient].add(amountReceived);

        if (!lottery.excludedFromLottery(recipient)) {
            try lottery.setShare(sender, _balances[sender]) {} catch {}
        }

        emit Transfer(sender, recipient, amountReceived);
        return true;
    }


    function _basicTransfer(
        address sender,
        address recipient,
        uint256 amount
    )
    internal
    returns (bool)
    {
        _balances[sender] = _balances[sender].sub(
            amount,
            "Insufficient Balance"
        );
        _balances[recipient] = _balances[recipient].add(amount);
        emit Transfer(sender, recipient, amount);
        return true;
    }

    // Lottery Functions
    function timeUntilDraw() external returns (uint){
        uint nextDrawing = lottery.lastDrawing() + lottery.timeBetweenDrawings();
        if (block.timestamp >= nextDrawing) {
            return 0;
        }
        else {
            return nextDrawing - block.timestamp;
        }
    }

    function pickWinners() external {
        require(!lottery.drawingCompleted(lottery.iteration()), "This drawing has already concluded");
        require(block.timestamp > lottery.lastDrawing() + lottery.timeBetweenDrawings(), "You cant pick winners yet");
        if (balanceOf(address(this)) > 0) {
            triggerSwapBack();
        }
        payable(address(lottery)).transfer(address(this).balance);
        lottery.pickWinners();
    }

    function setNumWinners(uint numWinners) external authorized {
        lottery.setNumWinners(numWinners);
    }

    function setMinHolding(uint minHolding) external authorized {
        lottery.setMinHolding(minHolding);
    }

    function setTimeBetweenDrawings(uint timeBetween) external authorized {
        lottery.setTimeBetweenDrawings(timeBetween);
    }

    function setExcludedFromLottery(address user, bool value) public authorized {
        lottery.setExcludedFromLottery(user, value);
    }


    function shouldTakeFee(
        address sender,
        address recipient
    )
    internal
    view
    returns (bool)
    {
        if (isFeeExempt[sender] || isFeeExempt[recipient]) {
            return false;
        }
        else if (sender != pair && recipient != pair) {
            return false;
        }
        return true;
    }


    function getTotalFee(
        bool selling
    )
    public
    view
    returns (uint256)
    {
        if (selling) {
            return getMultipliedFee();
        }
        return totalFee;
    }


    function getMultipliedFee()
    public
    view
    returns (uint256)
    {
        if (sellMultiplierEnabled) {
            return totalFee.mul(sellMultiplier);
        }
        return totalFee;
    }


    function takeFee(
        address sender,
        address receiver,
        uint256 amount
    )
    internal
    returns (uint256)
    {
        uint256 feeAmount = amount.mul(getTotalFee(receiver == pair)).div(
            feeDenominator
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }


    function takeSniperFee(
        address sender,
        uint256 amount
    )
    internal
    returns (uint256)
    {
        uint256 feeAmount = amount.mul(sniperFee).div(
            feeDenominator
        );

        _balances[address(this)] = _balances[address(this)].add(feeAmount);
        emit Transfer(sender, address(this), feeAmount);

        return amount.sub(feeAmount);
    }


    function shouldSwapBack()
    internal
    view
    returns (bool)
    {
        return
        msg.sender != pair &&
        !inSwap &&
        swapEnabled &&
        _balances[address(this)] >= swapThreshold;
    }

    function triggerSwapBack()
    internal
    {
        uint balance = balanceOf(address(this));
        swapBack(balance);
    }


    function swapBack(uint _swapThreshold)
    internal
    swapping
    {
        uint256 amountToLiquify = _swapThreshold
        .mul(liquidityFee)
        .div(totalFee)
        .div(2);
        uint256 amountToSwap = _swapThreshold.sub(amountToLiquify);

        address[] memory path = new address[](2);
        path[0] = address(this);
        path[1] = router.WETH();
        uint256 balanceBefore = address(this).balance;

        router.swapExactTokensForETHSupportingFeeOnTransferTokens(
            amountToSwap,
            0,
            path,
            address(this),
            block.timestamp
        );

        uint256 amountBNB = address(this).balance.sub(balanceBefore);

        uint256 totalBNBFee = totalFee.sub(liquidityFee.div(2));

        uint256 amountBNBLiquidity = amountBNB
        .mul(liquidityFee)
        .div(totalBNBFee)
        .div(2);


        if (amountToLiquify > 0) {
            router.addLiquidityETH{value: amountBNBLiquidity}(
                address(this),
                amountToLiquify,
                0,
                0,
                autoLiquidityReceiver,
                block.timestamp
            );
            emit AutoLiquify(amountBNBLiquidity, amountToLiquify);
        }
    }

    function setRoute(
        address _router,
        address _pair
    )
    external
    authorized
    {
        router = IDexRouter(_router);
        pair = _pair;
    }


    function setIsFeeExempt(
        address holder,
        bool exempt
    )
    external
    authorized
    {
        isFeeExempt[holder] = exempt;
    }


    function setFees(
        uint256 _liquidityFee,
        uint256 _lotteryFee,
        uint256 _feeDenominator
    )
    external
    authorized
    {
        liquidityFee = _liquidityFee;
        lotteryFee = _lotteryFee;
        totalFee = _liquidityFee.add(_lotteryFee);
        feeDenominator = _feeDenominator;
        require(
            totalFee < feeDenominator / 4,
            "Total fee should not be greater than 1/4 of fee denominator"
        );
    }


    function setFeeReceivers(
        address _autoLiquidityReceiver
    )
    external
    authorized
    {
        autoLiquidityReceiver = _autoLiquidityReceiver;
    }


    function setSwapBackSettings(
        bool _enabled,
        uint256 _amount
    )
    external
    authorized
    {
        swapEnabled = _enabled;
        swapThreshold = _amount;
    }


    function getCirculatingSupply()
    public
    view
    returns (uint256)
    {
        return _totalSupply.sub(balanceOf(DEAD)).sub(balanceOf(ZERO));
    }


    function setSellMultiplier(
        bool _enabled,
        uint256 _multiplier
    )
    external
    authorized
    {
        require(_multiplier <= 2, "Sell Multiplier Cannot be more than 2x");
        sellMultiplierEnabled = _enabled;
        sellMultiplier = _multiplier;
    }
}
