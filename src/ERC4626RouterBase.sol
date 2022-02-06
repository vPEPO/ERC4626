// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.10;

import {IERC4626, IERC4626Router, ERC20} from "./interfaces/IERC4626Router.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";

import {SelfPermit} from "./external/SelfPermit.sol";
import {Multicall} from "./external/Multicall.sol";
import {PeripheryPayments, IWETH9} from "./external/PeripheryPayments.sol";

/// @title ERC4626 router base contract
/// @author joeysantoro
abstract contract ERC4626RouterBase is IERC4626Router, SelfPermit, Multicall, PeripheryPayments {
    using SafeTransferLib for ERC20;

    function approveMint(
        IERC4626 vault, 
        uint256 shares
    ) public {
        approve(vault.asset(), address(vault), vault.previewMint(shares));
    }

    function mint(
        IERC4626 vault, 
        address to,
        uint256 shares,
        uint256 maxAmountIn
    ) public returns (uint256 amountIn) {
        if ((amountIn = vault.mint(shares, to)) > maxAmountIn) {
            revert MinAmountError();
        }
    }

    function deposit(
        IERC4626 vault, 
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) public returns (uint256 sharesOut) {
        if ((sharesOut = vault.deposit(amount, to)) < minSharesOut) {
            revert MinAmountError();
        }
    }

    function depositMax(
        IERC4626 vault, 
        address to,
        uint256 minSharesOut
    ) public returns (uint256 sharesOut) {
        uint256 assetBalance = vault.asset().balanceOf(address(this));
        uint256 maxDeposit = vault.maxDeposit(to);
        return deposit(vault, to, maxDeposit > assetBalance ? maxDeposit : assetBalance, minSharesOut);
    }

    function approveWithdraw(
        IERC4626 vault, 
        uint256 amount
    ) public {
        approve(vault, address(vault), vault.previewWithdraw(amount));
    }

    function withdraw(
        IERC4626 vault,
        address to,
        uint256 amount,
        uint256 minSharesOut
    ) public override returns (uint256 sharesOut) {
        if ((sharesOut = vault.withdraw(amount, to, msg.sender)) < minSharesOut) {
            revert MinAmountError();
        }
    }

    function redeem(
        IERC4626 vault,
        address to,
        uint256 shares,
        uint256 minAmountOut
    ) public override returns (uint256 amountOut) {
        if ((amountOut = vault.redeem(shares, to, msg.sender)) < minAmountOut) {
            revert MinAmountError();
        }
    }

    function redeemMax(
        IERC4626 vault, 
        address to,
        uint256 minAmountOut
    ) public returns (uint256 amountOut) {
        uint256 shareBalance = vault.balanceOf(address(this));
        uint256 maxRedeem = vault.maxRedeem(msg.sender);
        return redeem(vault, to, maxRedeem > shareBalance ? maxRedeem : shareBalance, minAmountOut);
    }
}