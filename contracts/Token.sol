Awesome sauce. Getting a test issue here with this code using hardhat: pragma solidity 0.7.0;

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

  // IERC20

  pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DividendToken is ERC20 {


    address[] private holders;

    mapping(address => bool) public isHolder;
    mapping(address => uint256) private holderIndex;


    mapping(address => uint256) public pendingDividends;

    bool private _locked;

    modifier nonReentrant() {
        require(!_locked, "Reentrant call");
        _locked = true;
        _;
        _locked = false;
    }


    constructor() ERC20("Dividend Token", "DIV") {}


    function mint() external payable {
        require(msg.value > 0);

        _mint(msg.sender, msg.value);

        _addHolder(msg.sender);
    }


function burn(uint256 amount) external nonReentrant {
    require(balanceOf(msg.sender) >= amount, "Insufficient balance");
    
    _burn(msg.sender, amount);

    if (balanceOf(msg.sender) == 0) {
        _removeHolder(msg.sender);
    }

    (bool success,) = payable(msg.sender).call{value: amount}("");
    require(success, "Transfer failed");
}


    function assignDividends() external payable {

        require(msg.value > 0);

        uint256 supply = totalSupply();
        uint256 holderCount = holders.length;

        for (uint256 i; i < holderCount;) {

            address holder = holders[i];

            uint256 payment =
                (msg.value * balanceOf(holder)) / supply;

            pendingDividends[holder] += payment;

            unchecked {
                ++i;
            }
        }
    }


    function claimDividend() external {

        uint256 amount = pendingDividends[msg.sender];

        require(amount > 0);

        pendingDividends[msg.sender] = 0;

        payable(msg.sender).transfer(amount);
    }


    function _update(
        address from,
        address to,
        uint256 amount
    ) internal override {

        super._update(from, to, amount);

        if (from != address(0)) {
            if (balanceOf(from) == 0 && isHolder[from]) {
                _removeHolder(from);
            }
        }

        if (to != address(0)) {
            if (!isHolder[to] && balanceOf(to) > 0) {
                _addHolder(to);
            }
        }
    }


    function _addHolder(address holder) internal {

        if (isHolder[holder]) return;

        isHolder[holder] = true;

        holderIndex[holder] = holders.length;

        holders.push(holder);
    }

    function _removeHolder(address holder) internal {

        uint256 index = holderIndex[holder];

        uint256 last = holders.length - 1;

        address lastHolder = holders[last];

        holders[index] = lastHolder;

        holderIndex[lastHolder] = index;

        holders.pop();

        delete holderIndex[holder];

        isHolder[holder] = false;
    }

    function holderCount() external view returns(uint256){
        return holders.length;
    }

}