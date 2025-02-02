# ERC4626 Ecosystem Utilities

This repository contains open-source ERC4626 infrastructure that can be used by solidity developers using [EIP-4626](https://eips.ethereum.org/EIPS/eip-4626), including ERC4626Router (the canonical ERC-4626 multicall router) and xERC4626. Powered by [forge](https://github.com/gakonst/foundry/tree/master/forge) and [solmate](https://github.com/Rari-Capital/solmate).

## About ERC-4626

[EIP-4626: The Tokenized Vault Standard](https://eips.ethereum.org/EIPS/eip-4626) is an ethereum application developer interface for building token vaults and strategies. It is meant to consolidate development efforts around "single token strategies" such as lending, yield aggregators, and single-sided staking.

## ERC4626Router and Base

ERC-4626 standardizes the interface around depositing and withdrawing tokens from strategies.

The ERC4626 Router is an ecosystem utility contract (like WETH) which can route tokens in and out of multiple ERC-4626 strategies in a single call. Its architecture was inspired by the [Uniswap V3 multicall router](https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol).

Basic supported features include:
* withdrawing from some Vault A and redepositing to Vault B
* wrapping and unwrapping WETH
* managing token approvals/transfers
* slippage protection

Ultimately the ERC4626 router can support an arbitrary number of withdrawals, deposits, and even distinct token types in a single call, subject to the block gas limit.

The router is split between the base [ERC4626RouterBase](https://github.com/fei-protocol/ERC4626/blob/main/src/ERC4626RouterBase.sol) which only handles the ERC4626 mutable methods (deposit/withdraw/mint/redeem) and the main router [ERC4626Router](https://github.com/fei-protocol/ERC4626/blob/main/src/ERC4626Router.sol) which includes support for common routing flows and max logic.

### Using the Router
The router is a multicall-style router, meaning it can atomically perform any number of supported actions on behalf of the message sender.

Some example user flows are listed below.

Vault deposit (requires ERC-20 approval of vault underlying asset before calling OR use a self-permit):
- PeripheryPayments.approve(asset, vault, amount) approves the vault to spend asset of the router
- ERC4626Router.depositToVault

WETH vault redeem (requires the router to have ERC-20 approval of the vault shares before calling OR use a self-permit):
- ERC4626Router.redeem *to* the router
- PeripheryPayments.unwrapWETH9 *to* the user destination

2 to 1 vault consolidation (requires ERC-20 approval of both source vault underlying assets OR self-permit):
- ERC4626RouterBase.withdraw (or redeem) on vault A *to* the router
- ERC4626RouterBase.withdraw (or redeem) on vault B *to* the router
- PeripheryPayments.approve(asset, vault C, amount) approves the vault to spend asset of the router
- ERC4626RouterBase.deposit on destination vault C

---
It is REQUIRED to use multicall to interact across multi-step user flows. The router is stateless other than holding token approvals for vaults it interacts with. Any tokens that end a transaction in the router can be permissionlessly withdrawn by any address, likely an MEV searcher, so make sure to complete all multicalls with token withdrawals to an end user address.

It is recommended to max approve vaults, and check whether a vault is already approved before interacting with the vault. This can save user gas. In cases where the number of required steps in a user flow is reduced to 1, a direct call can be used instead of multicall.

---
The router will be immutably deployed to `router.4626.eth` as soon as the contracts are frozen and reviewed.

[ERC4626RouterBase](https://github.com/fei-protocol/ERC4626/blob/main/src/ERC4626RouterBase.sol) - basic ERC4626 methods

[ERC4626Router](https://github.com/fei-protocol/ERC4626/blob/main/src/ERC4626Router.sol) - combined ERC4626 methods

[PeripheryPayments](https://github.com/fei-protocol/ERC4626/blob/main/src/external/PeripheryPayments.sol) - WETH and ERC-20 utility methods

[Multicall](https://github.com/fei-protocol/ERC4626/blob/main/src/external/Multicall.sol) - multicall utility

[SelfPermit](https://github.com/fei-protocol/ERC4626/blob/main/src/external/SelfPermit.sol) - user approvals to the router with EIP-712 and EIP-2612

### Extending the Router

The router can be imported and extended. Many ERC-4626 use cases include additional methods which may want to be included in a multicall router.

Importing via npm: **coming soon**
Importing via [forge](https://github.com/gakonst/foundry/tree/master/forge): `forge install Fei-Protocol/ERC4626`

Examples:
* [Tribe Turbo - TurboRouter](https://github.com/fei-protocol/tribe-turbo/blob/main/src/TurboRouter.sol)

## xERC4626
An "xToken" popularized by SushiSwap with xSUSHI is a single-sided autocompounding token rewards module.

xTokens were improved apon by Zephram Lou with [xERC20](https://github.com/ZeframLou/playpen/blob/main/src/xERC20.sol) to include manipulation resistant reward distributions.

Because xTokens are a perfect use case of ERC-4626, a base utility called xERC4626 is included in this repo. 

xERC4626 improvements:
* 4626 complete interface compatibility
* completely internal accounting to prevent all forms of exchange rate manipulation

xERC4626 examples:
* [xTRIBE](https://github.com/fei-protocol/xTRIBE/blob/master/src/xTRIBE.sol)
