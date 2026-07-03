pragma solidity 0.7.0;

import "./IERC20.sol";
import "./IMintableToken.sol";
import "./IDividends.sol";
import "./SafeMath.sol";

contract Token is IERC20, IMintableToken, IDividends {
  // ------------------------------------------ //
  // ----- BEGIN: DO NOT EDIT THIS SECTION ---- //
  // ------------------------------------------ //
  using SafeMath for uint256;
  uint256 public totalSupply;
  uint256 public decimals = 18;
  string public name = "Test token";
  string public symbol = "TEST";
  mapping (address => uint256) public balanceOf;
  // ------------------------------------------ //
  // ----- END: DO NOT EDIT THIS SECTION ------ //  
  // ------------------------------------------ //

  // --- Custom State Variables for Dividend Functionality ---
  address[] private holders;
  mapping(address => bool) public isHolder;
  mapping(address => uint256) private holderIndex;
  mapping(address => uint256) public pendingDividends;

  // --- IERC20 Allowances Mapping ---
  mapping(address => mapping(address => uint256)) private _allowances;

  bool private _locked;
  modifier nonReentrant() {
      require(!_locked, "Reentrant call");
      _locked = true;
      _;
      _locked = false;
  }

  // --- IERC20 Core Functions ---
  function allowance(address owner, address spender) external view override returns (uint256) {
      return _allowances[owner][spender];
  }

  function approve(address spender, uint256 value) external override returns (bool) {
      _allowances[msg.sender][spender] = value;
      return true;
  }

  function transfer(address to, uint256 value) external override returns (bool) {
      _transfer(msg.sender, to, value);
      return true;
  }

  function transferFrom(address from, address to, uint256 value) external override returns (bool) {
      require(_allowances[from][msg.sender] >= value, "ERC20: transfer amount exceeds allowance");
      _allowances[from][msg.sender] = _allowances[from][msg.sender].sub(value);
      _transfer(from, to, value);
      return true;
  }

  // --- IMintableToken & IDividends Custom Implementation ---
  function mint() external payable override {
      require(msg.value > 0, "Cannot mint 0");
      totalSupply = totalSupply.add(msg.value);
      balanceOf[msg.sender] = balanceOf[msg.sender].add(msg.value);
      _adjustHolderStatus(address(0), msg.sender);
  }

  function burn(address payable dest) external override nonReentrant {
      uint256 amount = balanceOf[msg.sender];
      require(amount > 0, "Insufficient balance");
      
      balanceOf[msg.sender] = 0;
      totalSupply = totalSupply.sub(amount);
      _adjustHolderStatus(msg.sender, address(0));

      (bool success,) = dest.call{value: amount}("");
      require(success, "Transfer failed");
  }

  function recordDividend() external payable override {
      require(msg.value > 0, "Cannot record empty dividend");
      uint256 supply = totalSupply;
      uint256 holderCount = holders.length;

      for (uint256 i = 0; i < holderCount; i++) {
          address holder = holders[i];
          uint256 payment = (msg.value.mul(balanceOf[holder])) / supply;
          pendingDividends[holder] = pendingDividends[holder].add(payment);
      }
  }

  function withdrawDividend(address payable dest) external override {
      uint256 amount = pendingDividends[msg.sender];
      require(amount > 0, "No dividends to withdraw");
      pendingDividends[msg.sender] = 0;
      dest.transfer(amount);
  }

  function getWithdrawableDividend(address payee) external view override returns (uint256) {
      return pendingDividends[payee];
  }

  function getNumTokenHolders() external view override returns (uint256) {
      return holders.length;
  }

  function getTokenHolder(uint256 index) external view override returns (address) {
      require(index > 0 && index <= holders.length, "Index out of bounds");
      return holders[index - 1]; // Adjusts for the 1-based index loop in JavaScript tests
  }

  // --- Internal Helper Management ---
  function _transfer(address from, address to, uint256 amount) internal {
      require(from != address(0), "Transfer from zero address");
      require(to != address(0), "Transfer to zero address");
      balanceOf[from] = balanceOf[from].sub(amount);
      balanceOf[to] = balanceOf[to].add(amount);
      _adjustHolderStatus(from, to);
  }

  function _adjustHolderStatus(address from, address to) internal {
      if (from != address(0) && balanceOf[from] == 0 && isHolder[from]) {
          _removeHolder(from);
      }
      if (to != address(0) && !isHolder[to] && balanceOf[to] > 0) {
          _addHolder(to);
      }
  }

  function _addHolder(address holder) internal {
      if (isHolder[holder]) return;
      isHolder[holder] = true;
      holderIndex[holder] = holders.length;
      holders.push(holder);
  }

  function _removeHolder(address holder) internal {
      if (!isHolder[holder]) return;
      uint256 index = holderIndex[holder];
      uint256 last = holders.length - 1;
      address lastHolder = holders[last];
      
      holders[index] = lastHolder;
      holderIndex[lastHolder] = index;
      holders.pop();

      delete holderIndex[holder];
      isHolder[holder] = false;
  }
}

