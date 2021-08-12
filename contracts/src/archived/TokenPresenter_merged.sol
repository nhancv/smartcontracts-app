// SPDX-License-Identifier: MIT
pragma solidity 0.8.3;


/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * IMPORTANT: Beware that changing an allowance with this method brings the risk
     * that someone may use both the old and the new allowance by unfortunate
     * transaction ordering. One possible solution to mitigate this race
     * condition is to first reduce the spender's allowance to 0 and set the
     * desired value afterwards:
     * https://github.com/ethereum/EIPs/issues/20#issuecomment-263524729
     *
     * Emits an {Approval} event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a {Transfer} event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to {approve}. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface ITokenPresenter {
  function receiveTokens(address _from, address _to, uint256 _value) external returns (bool);
  function receiveTokensFrom(address trigger, address _from, address _to, uint256 _amount) external returns (bool);
}

/*
 * @dev Provides information about the current execution context, including the
 * sender of the transaction and its data. While these are generally available
 * via msg.sender and msg.data, they should not be accessed in such a direct
 * manner, since when dealing with meta-transactions the account sending and
 * paying for execution may not be the actual sender (as far as an application
 * is concerned).
 *
 * This contract is only required for intermediate, library-like contracts.
 */
abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        this; // silence state mutability warning without generating bytecode - see https://github.com/ethereum/solidity/issues/2691
        return msg.data;
    }
}

/**
 * @dev Contract module which provides a basic access control mechanism, where
 * there is an account (an owner) that can be granted exclusive access to
 * specific functions.
 *
 * By default, the owner account will be the one that deploys the contract. This
 * can later be changed with {transferOwnership}.
 *
 * This module is used through inheritance. It will make available the modifier
 * `onlyOwner`, which can be applied to your functions to restrict their use to
 * the owner.
 */
abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        address msgSender = _msgSender();
        _owner = msgSender;
        emit OwnershipTransferred(address(0), msgSender);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions anymore. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby removing any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        emit OwnershipTransferred(_owner, address(0));
        _owner = address(0);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}

contract Maintainable is Ownable {

  bool public isMaintenance = false;
  bool public isOutdated = false;

  // Check if contract is not in maintenance
  function ifNotMaintenance() internal view {
    require(!isMaintenance, "Maintenance");
    require(!isOutdated, "Outdated");
  }

  // Check if contract on maintenance for restore
  function ifMaintenance() internal view {
    require(isMaintenance, "!Maintenance");
  }

  // Enable maintenance
  function enableMaintenance(bool status) onlyOwner public {
    isMaintenance = status;
  }

  // Enable outdated
  function enableOutdated(bool status) onlyOwner public {
    isOutdated = status;
  }

}

contract TokenPresenter is ITokenPresenter, Maintainable {

  address public token;

  event Received(address sender, uint amount);

  constructor() {
    token = address(0);
  }

  receive() external payable {
    emit Received(msg.sender, msg.value);
  }

  function setToken(address _token) onlyOwner public {
    token = _token;
  }

  function receiveTokens(address _from, address _to, uint256 _amount) public override returns (bool) {
    return receiveTokensFrom(_from, _from, _to, _amount);
  }

  function receiveTokensFrom(address _trigger, address _from, address _to, uint256 _amount) public override returns (bool) {
    ifNotMaintenance();
    require(msg.sender == token, "TokenPresenter: Only trigger from token");
    IERC20(token).transfer(_to, _amount);
    return true;
  }

  function getEthBalance() public view onlyOwner returns (uint) {
    return address(this).balance;
  }

  function withdrawEthBalance() external onlyOwner {
    payable(owner()).transfer(getEthBalance());
  }

  function getTokenBalance(address _tokenAddress) public view onlyOwner returns (uint) {
    IERC20 erc20 = IERC20(_tokenAddress);
    return erc20.balanceOf(address(this));
  }

  function withdrawTokenBalance(address _tokenAddress) external onlyOwner {
    IERC20 erc20 = IERC20(_tokenAddress);
    erc20.transfer(
      owner(),
      getTokenBalance(_tokenAddress)
    );
  }
}
