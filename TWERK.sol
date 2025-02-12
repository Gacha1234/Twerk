pragma solidity ^0.5.0;

interface IERC20 {
  function totalSupply() external view returns (uint256);
  function balanceOf(address who) external view returns (uint256);
  function allowance(address owner, address spender) external view returns (uint256);
  function transfer(address to, uint256 value) external returns (bool);
  function approve(address spender, uint256 value) external returns (bool);
  function transferFrom(address from, address to, uint256 value) external returns (bool);
  function _mint(address account, uint256 amount) external returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
  event DividentTransfer(address from , address to , uint256 value);
}
library SafeMath {
  function mul(uint256 a, uint256 b) internal pure returns (uint256) {
    if (a == 0) {
      return 0;
    }
    uint256 c = a * b;
    assert(c / a == b);
    return c;
  }
  function div(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a / b;
    return c;
  }
  function sub(uint256 a, uint256 b) internal pure returns (uint256) {
    assert(b <= a);
    return a - b;
  }
  function add(uint256 a, uint256 b) internal pure returns (uint256) {
    uint256 c = a + b;
    assert(c >= a);
    return c;
  }
  function ceil(uint256 a, uint256 m) internal pure returns (uint256) {
    uint256 c = add(a,m);
    uint256 d = sub(c,1);
    return mul(div(d,m),m);
  }
}
contract ERC20Detailed is IERC20 {
  string private _name;
  string private _symbol;
  uint8 private _decimals;
  constructor(string memory name, string memory symbol, uint8 decimals) public {
    _name = name;
    _symbol = symbol;
    _decimals = decimals;
  }
  function name() public view returns(string memory) {
    return _name;
  }
  function symbol() public view returns(string memory) {
    return _symbol;
  }
  function decimals() public view returns(uint8) {
    return _decimals;
  }
}
contract Owned {
    address payable public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);
    constructor() public {
        owner = msg.sender;
    }



    modifier onlyOwner{
        require(msg.sender == owner );
        _;
    }

    function transferOwnership(address payable _newOwner) public onlyOwner {
        owner = _newOwner;
    }
}
contract DeflationToken is ERC20Detailed, Owned {

  using SafeMath for uint256;
  mapping (address => uint256) private _balances;
  mapping (address => mapping (address => uint256)) private _allowed;
  mapping (address => bool) public _freezed;
  string constant tokenName = "TWERK";
  string constant tokenSymbol = "TWERK";
  uint8  constant tokenDecimals = 6;
  uint256 _totalSupply ;
  uint256 public baseThreePercent = 300;
  uint256 public basePercent = 100;


  IERC20 public InflationToken;
  address public inflationTokenAddress;


  constructor() public  ERC20Detailed(tokenName, tokenSymbol, tokenDecimals) {
    _mint( msg.sender,  60000 * 1000000);
  }


    function freezeAccount (address account) public onlyOwner{
        _freezed[account] = true;
    }

     function unFreezeAccount (address account) public onlyOwner{
        _freezed[account] = false;
    }



  function setInflationContractAddress(address tokenAddress) public  onlyOwner{
        InflationToken = IERC20(tokenAddress);
        inflationTokenAddress = tokenAddress;
    }



  function totalSupply() public view returns (uint256) {
    return _totalSupply;
  }
  function balanceOf(address owner) public view returns (uint256) {
    return _balances[owner];
  }
  function allowance(address owner, address spender) public view returns (uint256) {
    return _allowed[owner][spender];
  }
  function findThreePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(baseThreePercent);
    uint256 onePercent = roundValue.mul(baseThreePercent).div(10000);
    return onePercent;
  }
  function findOnePercent(uint256 value) public view returns (uint256)  {
    uint256 roundValue = value.ceil(basePercent);
    uint256 onePercent = roundValue.mul(basePercent).div(10000);
    return onePercent;
  }


  function transfer(address to, uint256 value) public returns (bool) {

    require(value <= _balances[msg.sender]);
    require(to != address(0));
    require(_freezed[msg.sender] != true);
    require(_freezed[to] != true);

    uint256 tokensToBurnAndMint = findThreePercent(value);
    uint256 devTokens = findOnePercent(value);

    uint256 tokensToTransfer = value.sub(tokensToBurnAndMint);
    tokensToTransfer = tokensToTransfer.sub(devTokens);
    InflationToken._mint(msg.sender, tokensToBurnAndMint);

    _balances[msg.sender] = _balances[msg.sender].sub(value);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _balances[owner] = _balances[owner].add(devTokens);
    _totalSupply = _totalSupply.sub(tokensToBurnAndMint);

    emit Transfer(msg.sender, owner, devTokens);
    emit Transfer(msg.sender, to, tokensToTransfer);
    emit Transfer(msg.sender, address(0), tokensToBurnAndMint);

    return true;
  }


  function approve(address spender, uint256 value) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = value;
    emit Approval(msg.sender, spender, value);
    return true;
  }
  function transferFrom(address from, address to, uint256 value) public returns (bool) {
    require(value <= _balances[from]);
    require(value <= _allowed[from][msg.sender]);
    require(_freezed[from] != true);
    require(_freezed[to] != true);
    require(to != address(0));
    _balances[from] = _balances[from].sub(value);

    uint256 tokensToBurnAndMint = findThreePercent(value);
    uint256 devTokens = findOnePercent(value);

    uint256 tokensToTransfer = value.sub(tokensToBurnAndMint);
    tokensToTransfer = tokensToTransfer.sub(devTokens);

    _balances[owner] = _balances[owner].add(devTokens);
    _balances[to] = _balances[to].add(tokensToTransfer);
    _totalSupply = _totalSupply.sub(tokensToBurnAndMint);
    InflationToken._mint(from , tokensToBurnAndMint);
    _allowed[from][msg.sender] = _allowed[from][msg.sender].sub(value);

    emit Transfer(from, to, tokensToTransfer);
    emit Transfer(from, owner, devTokens);
    emit Transfer(from, address(0), tokensToBurnAndMint);
    return true;
  }
  function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].add(addedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }
  function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
    require(spender != address(0));
    _allowed[msg.sender][spender] = (_allowed[msg.sender][spender].sub(subtractedValue));
    emit Approval(msg.sender, spender, _allowed[msg.sender][spender]);
    return true;
  }


  function _mint(address account, uint256 amount) onlyOwner public returns (bool){
    require(amount != 0);
    _balances[account] = _balances[account].add(amount);
     _totalSupply = _totalSupply.add(amount);
    emit Transfer(address(0), account, amount);
    return true;
  }

  function burn(uint256 amount) external {
    _burn(msg.sender, amount);
  }


  function _burn(address account, uint256 amount) internal {
    require(amount != 0);
    require(amount <= _balances[account]);
    _totalSupply = _totalSupply.sub(amount);
    _balances[account] = _balances[account].sub(amount);
    emit Transfer(account, address(0), amount);
  }
  function burnFrom(address account, uint256 amount) external {
    require(amount <= _allowed[account][msg.sender]);
    _allowed[account][msg.sender] = _allowed[account][msg.sender].sub(amount);
    _burn(account, amount);
  }
}
