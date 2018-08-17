defmodule FinancialSystem do
  @moduledoc """
    Provides methods to do financial operations, such as account creation, currency exchange and transfers.
  """
  alias Decimal, as: D

  @doc """
    Create a client account in aour Financial System.
    Each account is able to store just one currency type

  ## Examples

      iex> FinancialSystem.create_account(1, "Lucas Rolim", :BRL)
      %FinancialSystem.Account{
        balance: %Currency.Money{
          amount: Decimal.new("0.00"),
          currency: :BRL,
          precision: 2,
          symbol: nil
        },
        currency: :BRL,
        id: 1,
        owner: "Lucas Rolim"
      }
  """
  def create_account(account_id, owner_name, currency) do
    %FinancialSystem.Account{
      id: account_id,
      owner: owner_name,
      currency: currency,
      balance: Currency.new(0, currency)
    }
  end

  def deposit(_account, deposit_value, _currecy)
      when deposit_value < 0 do
    raise("deposit value must be a positive number")
  end

  @doc """
    Deposits an amount into an user account.

  ## Examples

      iex> account = FinancialSystem.create_account(1, "Lucas Rolim", :JPY)
      iex> FinancialSystem.check_account_balance(account)
      "¥0"
      iex> account = FinancialSystem.deposit(account,10,:JPY)
      iex> FinancialSystem.check_account_balance(account)
      "¥10"
  """

  def deposit(
        %FinancialSystem.Account{balance: account_balance} = account,
        deposit_value,
        deposit_curency
      ) do
    new_balance = Currency.sum(Currency.new(deposit_value, deposit_curency), account_balance)
    %FinancialSystem.Account{account | balance: new_balance}
  end

  def withdrawal(_account, withdrawal_value, _currecy)
      when withdrawal_value < 0 do
    raise("withdrawal value must be a positive number")
  end

  @doc """
    Withdrawals an amount from an user account.

  ## Examples

      iex> account = FinancialSystem.create_account(1, "Lucas Rolim", :BRL)
      iex> FinancialSystem.check_account_balance(account)
      "R$0.00"
      iex> account = FinancialSystem.deposit(account,10,:BRL)
      iex> FinancialSystem.check_account_balance(account)
      "R$10.00"
      iex> account = FinancialSystem.withdrawal(account,5,:BRL)
      iex> FinancialSystem.check_account_balance(account)
      "R$5.00"
  """

  def withdrawal(
        %FinancialSystem.Account{balance: account_balance} = account,
        withdrawal_value,
        withdrawal_curency
      ) do
    new_balance =
      Currency.sub(account_balance, Currency.new(withdrawal_value, withdrawal_curency))

    %FinancialSystem.Account{account | balance: new_balance}
  end

  @doc """
    Checks if the account balance is bigger than a value.
  """
  def has_fund?(%FinancialSystem.Account{balance: %{amount: account_fund}}, value)
      when account_fund < value do
    raise("insufficient funds to complete the withdrawal")
  end

  @doc """
    Print the account balance and currency's symbol in string format

  ## Examples

      iex> account = FinancialSystem.create_account(1, "Lucas Rolim", :BRL)
      iex> FinancialSystem.check_account_balance(account)
      "R$0.00"
  """

  def check_account_balance(%FinancialSystem.Account{
        balance: %{amount: account_fund, currency: currency}
      }) do
    currencies =
      Currency.get_currencies()
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    currency_name = Map.get(currencies, currency)["symbol"]["grapheme"]
    currency_name <> Decimal.to_string(account_fund)
  end

  def transfer(
        %FinancialSystem.Account{currency: currency_b},
        %FinancialSystem.Account{currency: currency_a},
        _value
      )
      when currency_a !== currency_b do
    raise(
      "ordinary transfers must use the same currency. Consider to user international transfers"
    )
  end

  @doc """
    Print the account balance and currency's symbol in string format

  ## Examples

      iex> sender_account = FinancialSystem.create_account(1, "Fidalgo", :BRL)
      iex> sender_account = FinancialSystem.deposit(sender_account,10, :BRL)
      iex> receiver_account = FinancialSystem.create_account(2, "Amigo", :BRL)
      iex> {sender_account,receiver_account} = FinancialSystem.transfer(sender_account,receiver_account,5)
      iex> FinancialSystem.check_account_balance(receiver_account)
      "R$5.00"
  """

  def transfer(sender_account, receiver_account, value) do
    %FinancialSystem.Account{currency: currency} = sender_account
    sender_account = FinancialSystem.withdrawal(sender_account, value, currency)
    receiver_account = FinancialSystem.deposit(receiver_account, value, currency)
    {sender_account, receiver_account}
  end

  @doc """
    Transfers a value to multiple accounts according to given percentages

  ## Examples

      iex> sender_account = FinancialSystem.create_account(1, "Fidalgo", :BRL)
      iex> sender_account = FinancialSystem.deposit(sender_account,10, :BRL)
      iex> FinancialSystem.check_account_balance(sender_account)
      "R$10.00"
      iex> receiver_1 = FinancialSystem.create_account(2, "Mineirinho", :BRL)
      iex> receiver_2 = FinancialSystem.create_account(3, "Caju", :BRL)
      iex> {sender_account, [receiver_1,receiver_2]} = FinancialSystem.split_transfer(sender_account,[receiver_1,receiver_2], 10, [0.6,0.4])
      iex> FinancialSystem.check_account_balance(sender_account)
      "R$0.00"
      iex> FinancialSystem.check_account_balance(receiver_1)
      "R$6.00"
      iex> FinancialSystem.check_account_balance(receiver_2)
      "R$4.00"
  """

  def split_transfer(sender_account, receivers, value, percents) do
    %FinancialSystem.Account{currency: currency} = sender_account
    sender_account = FinancialSystem.withdrawal(sender_account, value, currency)

    weighted_values = Enum.map_every(percents, 1, fn x -> x * value end)

    receivers =
      receivers
      |> Enum.zip(weighted_values)
      |> Enum.map_every(1, fn receiver ->
        {receiver_account, weighted_value} = receiver

        deposit(receiver_account, weighted_value, currency)
      end)

    {sender_account, receivers}
  end

  def get_rates do
    url = System.get_env("EXCHANGE_API")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!()
        |> Map.get("rates")
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

      {:error, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Page not found")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end
end
