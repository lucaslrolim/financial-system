# Financial System 
![Travis](https://travis-ci.com/lucaslrolim/stone-challenge.svg?branch=master)
[![Coverage Status](https://coveralls.io/repos/github/lucaslrolim/stone-challenge/badge.svg)](https://coveralls.io/github/lucaslrolim/stone-challenge)

## About

This project was developed as part of the [Stone Tech Challenge](https://github.com/stone-payments/tech-challenge).  It intends to be a financial system able to do arbitrary precision financial operations in compliance with [ISO 4217](https://pt.wikipedia.org/wiki/ISO_4217). It also was my first contact with Elixir and the functional programming paradigm.

## Requeriments / Dependencies
- [Elixir 1.7](https://github.com/elixir-lang/elixir)
- [Poison](https://github.com/devinus/poison) *to parse JSON*
- [Decimal](https://github.com/ericmj/decimal) *to arithmetic operations with arbitrary* precision
- [HTTPotion](https://github.com/myfreeweb/httpotion) *to do HTTP requests and get currency exchange rates*
- [ExDoc](https://github.com/elixir-lang/ex_doc) *to generate documentation*

## Installation
1. `git clone https://github.com/lucaslrolim/stone-challenge`
2. `cd /stone-challenge`
3. `mix deps.get` to install dependencies
4. `iex -S mix` to start Elixir's interactive shell

## Modules

The project has five modules,but three are used to store customize structures and utility functions. The core modules are `Currency` and `FinancialSystem`.

### Currency module

The Currency module is used to create new elements to be operated by the financial system and ensure that these elements are in compliance with ISO 4217 standards. Besides that, it also implements arbitrary precision money operations, as sum and multiplication.

The following operations are available:

- Sum *as `sum(money_a ,money_b)`*
- Subtraction *as `sub(money_a ,money_b)`*
- Multiplication *as `mult(money, number)`*
- Disivion *as `div(money, number)`*

These functions were all built on top of the [Decimal](https://hexdocs.pm/decimal/readme.html) library. Also, the operations are all done in the `Money` customized structure, stored in the Money module.

A [JSON file](https://github.com/xsolla/currency-format/blob/master/currency-format.json) is used to get which are the valid currency codes and check if the user's input is correct.


### Financial System module

This is the project's core module.  It implements operations on `Money` and `Account` structures using the basic functions built on `Currency` module. An important aspect is that each account can operate on just one currency. Like in traditional bank accounts, the user needs to create different accounts to store different currencies, but it's possible to do an international transfer without the need to create a new account to this.

The following  operations are implemented:

- Deposit *as `deposit!(account, deposit_value, deposit_curency)	`*
- Withdrawal *as `withdrawal!(account, withdrawal_value, withdrawal_curency)`*
- Transfer *as `transfer!(sender_account, receiver_account, value)`*
- International transfer *as `transfer_international!(sender_account, receiver_account, to_currency, value)`*
- Check account balance *as `check_account_balance(account)`*

Also, there are functions to split a value among multiple accounts according to given percents. These functions are `split_value` and `split_transfer`.

Split transfer function splits a value among  N  other given accounts.  The distribution of the value follows the argument `percents`. This argument is a list that must sum 1.
```
iex> sender_account = FinancialSystem.create_account!(1, "Fidalgo", :BRL)
iex> sender_account = FinancialSystem.deposit!(sender_account,10, :BRL)
iex> FinancialSystem.check_account_balance(sender_account)
"R$10.00"
iex> receiver_1 = FinancialSystem.create_account!(2, "Mineirinho", :BRL)
iex> receiver_2 = FinancialSystem.create_account!(3, "Caju", :BRL)
iex> {sender_account, [receiver_1,receiver_2]} = FinancialSystem.split_transfer!(sender_account,[receiver_1,receiver_2], 10, [0.6,0.4])
iex> FinancialSystem.check_account_balance(sender_account)
"R$0.00"
iex> FinancialSystem.check_account_balance(receiver_1)
"R$6.00"
iex> FinancialSystem.check_account_balance(receiver_2)
"R$4.00"
```

The `split_value` function works in a similar way. It uses a list of accounts to split a deposit or withdrawal. The operation to be performed must be informed as a function argument. E.g:

```
iex> account_1 = FinancialSystem.create_account!(1, "Proximus", :BRL)
iex> account_2 = FinancialSystem.create_account!(2, "Bolinha", :BRL)
iex> account_3 = FinancialSystem.create_account!(3, "Botafogo", :BRL)
iex> [account_1,account_2,account_3] = FinancialSystem.split_value!([account_1, account_2, account_3],10,[0.5, 0.3, 0.2], &FinancialSystem.deposit!/3)
iex> FinancialSystem.check_account_balance(account_1)
"R$5.00"
iex> FinancialSystem.check_account_balance(account_2)
"R$3.00"
iex> FinancialSystem.check_account_balance(account_3)
"R$2.00"
```

Finally, the [Open Exchange Rates API](https://openexchangerates.org/) was used to implement the `exchange` function. So the conversion rates are handled at execution time and need an internet connection to works.

## Usage and tests

The basic usage instructions are explained on the [documentation page](http://determined-liskov-ff4672.netlify.com/api-reference.html). 

As a general rule positive tests were implemented as doctests and negative tests *(errors)* as unit tests in the test folder.

## Code quality

- [Travis](https://travis-ci.com/) *to continuous integration*
- [Coveralls](https://coveralls.io//) *to coverage tests*
- [Elixir Formatter](https://marketplace.visualstudio.com/items?itemName=sammkj.vscode-elixir-formatter) *to Elixir's style and conventions*
- [ElixirLS](https://github.com/JakeBecker/vscode-elixir-ls) *to debbug and Dialyzer analysis*
