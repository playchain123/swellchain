// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IERC20 {
    function approve(address spender, uint256 amount) external returns (bool);
    function balanceOf(address owner) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

interface IUniswapV2Router {
    function swapExactTokensForTokensSupportingFeeOnTransferTokens(
        uint amountIn,
        uint amountOutMin,
        address[] calldata path,
        address to,
        uint deadline
    ) external;
}

contract MetaPlayXArbitrage {
    address public owner;
    IERC20 public metaPlayX;
    address public dexRouter1;
    address public dexRouter2;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    constructor(address _metaPlayXAddress, address _dexRouter1, address _dexRouter2) {
        owner = msg.sender;
        metaPlayX = IERC20(_metaPlayXAddress);
        dexRouter1 = _dexRouter1;
        dexRouter2 = _dexRouter2;
    }

    function approveDexes() external onlyOwner {
        metaPlayX.approve(dexRouter1, type(uint256).max);
        metaPlayX.approve(dexRouter2, type(uint256).max);
    }

    function executeArbitrage(
        address[] calldata pathToBuy,
        address[] calldata pathToSell,
        uint amountIn,
        uint amountOutMinBuy,
        uint amountOutMinSell
    ) external onlyOwner {
        // Step 1: Buy MetaPlayX on dexRouter1
        IUniswapV2Router(dexRouter1).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            amountIn,
            amountOutMinBuy,
            pathToBuy,
            address(this),
            block.timestamp
        );

        uint256 metaBalance = metaPlayX.balanceOf(address(this));

        // Step 2: Sell MetaPlayX on dexRouter2
        IUniswapV2Router(dexRouter2).swapExactTokensForTokensSupportingFeeOnTransferTokens(
            metaBalance,
            amountOutMinSell,
            pathToSell,
            address(this),
            block.timestamp
        );
    }

    function withdrawTokens(address tokenAddress) external onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint balance = token.balanceOf(address(this));
        require(balance > 0, "No balance");
        token.transfer(owner, balance);
    }

    function updateDexes(address _dexRouter1, address _dexRouter2) external onlyOwner {
        dexRouter1 = _dexRouter1;
        dexRouter2 = _dexRouter2;
    }

    function updateMetaPlayX(address _metaPlayXAddress) external onlyOwner {
        metaPlayX = IERC20(_metaPlayXAddress);
    }
}
