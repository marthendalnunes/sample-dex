// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import '@openzeppelin/contracts/token/ERC20/ERC20.sol';

contract Exchange is ERC20 {
  address public cryptoDevTokenAddress;

  constructor(address _CryptoDevToken) ERC20('CryptoDev LP Token', 'CDLP') {
    require(
      _CryptoDevToken != address(0),
      'Crypto Dev token address cannot be a null address'
    );
    cryptoDevTokenAddress = _CryptoDevToken;
  }

  function getReserve() public view returns (uint256) {
    return ERC20(cryptoDevTokenAddress).balanceOf(address(this));
  }

  function addLiquidity(uint256 _amount) public payable returns (uint256) {
    uint256 liquidity;
    uint256 ethBalance = address(this).balance;
    uint256 cryptoDevTokenReserve = getReserve();
    ERC20 cryptoDevToken = ERC20(cryptoDevTokenAddress);
    if (cryptoDevTokenReserve == 0) {
      cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
      liquidity = ethBalance;
      _mint(msg.sender, liquidity);
    } else {
      uint256 ethReserve = ethBalance - msg.value;
      uint256 cryptoDevTokenAmount = (msg.value * cryptoDevTokenReserve) /
        (ethReserve);
      require(
        _amount >= cryptoDevTokenAmount,
        'Amount of tokens sent is less than the minimum tokens required'
      );
      cryptoDevToken.transferFrom(msg.sender, address(this), _amount);
      liquidity = (totalSupply() * msg.value) / ethReserve;
      _mint(msg.sender, liquidity);
    }
    return liquidity;
  }

  function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
    require(_amount > 0, 'Amount to remove should be greater than zero');
    uint256 ethReserve = address(this).balance;
    uint256 _totalSupply = totalSupply();
    uint256 ethAmount = (ethReserve * _amount) / _totalSupply;
    uint256 cryptoDevTokenAmount = (getReserve() * _amount) / _totalSupply;
    _burn(msg.sender, _amount);
    payable(msg.sender).transfer(ethAmount);
    ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
    return (ethAmount, cryptoDevTokenAmount);
  }

  function getAmountOfTOkens(
    uint256 inputAmount,
    uint256 inputReserve,
    uint256 outputReserve
  ) public pure returns (uint256) {
    require(inputAmount > 0, 'Input Amount cannot be negative');
    require(inputReserve > 0 && outputReserve > 0, 'Invalid reserves');
    uint256 inputAmountWithFees = (99 * inputAmount) / 100;
    return ((outputReserve * inputAmountWithFees) /
      (inputReserve + inputAmountWithFees));
  }

  function ethToCryptoDevToken(uint256 _minTokens) public payable {
    require(_minTokens > 0, 'Min tokens need to be greater than zero');
    uint256 ethReserve = address(this).balance - msg.value;
    uint256 tokenReserve = getReserve();
    uint256 cryptoDevTokenAmount = getAmountOfTOkens(
      msg.value,
      ethReserve,
      tokenReserve
    );
    require(cryptoDevTokenAmount >= _minTokens, 'Insufficient output amount');
    ERC20(cryptoDevTokenAddress).transfer(msg.sender, cryptoDevTokenAmount);
  }

  function cryptoDevTokensToEth(uint256 _tokensSold, uint256 _minEth) public {
    require(_minEth > 0, 'Minimun Eth needs to be greater than zero');
    uint256 tokenReserve = getReserve();
    uint256 ethBought = getAmountOfTOkens(
      _tokensSold,
      tokenReserve,
      address(this).balance
    );
    require(ethBought >= _minEth, 'Insufficient output amount');
    ERC20(cryptoDevTokenAddress).transferFrom(
      msg.sender,
      address(this),
      _tokensSold
    );
    payable(msg.sender).transfer(ethBought);
  }
}
