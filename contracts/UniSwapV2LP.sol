// SPDX-License-Identifier: GPL-3

pragma solidity ^0.8.14;

import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Pair.sol';
import '@uniswap/lib/contracts/libraries/TransferHelper.sol';
// import "./SafeMath.sol";

contract UniSwapV2LP {

// using SafeMath for uint;

address public immutable factory;
address public immutable WETH;

modifier ensure(uint deadline) {
    require(deadline >= block.timestamp, "EXPIRED");
    _;
}

constructor(address _factory, address _WETH) {
    factory = _factory;
    WETH = _WETH;
}

/** 
    UniSwapV2Library.sol
*/

function sortTokens(address tokenX, address tokenY) internal pure returns(address token0, address token1) {
    require(tokenX != tokenY, "You cannot provide LP for the same address");
    (token0, token1) = tokenX < tokenY ? (tokenX, tokenY) : (tokenY, tokenX);
    require(token0 != address(0), "Ensure it is not a null address");
}

function pairFor(address _factory, address tokenX, address tokenY) internal pure returns (address pair) {
    (address token0, address token1) = sortTokens(tokenX, tokenY);
    pair = address(uint160(bytes20(keccak256(abi.encodePacked(
        hex'ff',
        _factory,
        keccak256(abi.encodePacked(token0, token1)),
        hex'96e8ac4277198ff8b6f785478aa9a39f403cb768dd02cbee326c3e7da348845f'
    )))));
}

function getReserves(address _factory, address tokenX, address tokenY) internal view returns(uint reserveX, uint reserveY) {
    (address token0,) = sortTokens(tokenX, tokenY);
    (uint reserve0, uint reserve1,) = IUniswapV2Pair(pairFor(_factory, tokenX, tokenY)).getReserves();
    (reserveX, reserveY) = tokenX == token0 ? (reserve0, reserve1) : (reserve1, reserve0);
}


/** 
    Add Liquidity
*/

function _addLiquidity(
    address tokenX,
    address tokenY,
    uint amountAaddedToLP,
    uint amountBaddedToLP
    // uint amountAminaddedToLP,
    // uint amountBminaddedToLP
) internal virtual returns(uint amountA, uint amountB) {
    if(IUniswapV2Factory(factory).getPair(tokenX, tokenY) == address(0)){
        IUniswapV2Factory(factory).createPair(tokenY, tokenX);
    }

    (uint reserveA, uint reserveB) = getReserves(factory, tokenX, tokenY);
    if(reserveA == 0 && reserveB == 0) {
        (amountA, amountB) = (amountAaddedToLP, amountBaddedToLP);
    } 
} 

function addLiquidity(
    address tokenX,
    address tokenY,
    uint amountXaddedToLP,
    uint amountYaddedToLP,
    address to,
    uint deadline
) public ensure(deadline) returns(uint amount0, uint amount1, uint liquidity) {
    (amount0, amount1) = _addLiquidity(tokenX, tokenY, amountXaddedToLP, amountYaddedToLP);
    address pair = pairFor(factory, tokenX, tokenY);
    TransferHelper.safeTransferFrom(tokenX, msg.sender, pair, amount0);
    TransferHelper.safeTransferFrom(tokenY, msg.sender, pair, amount1);
    liquidity = IUniswapV2Pair(pair).mint(to); // This is where the reward tokens will . It calls the mint function from the Core Contract
}


}
