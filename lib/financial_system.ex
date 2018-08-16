defmodule FinancialSystem do

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

  def deposit(%FinancialSystem.Account{balance: account_balance} = account, deposit_value, deposit_curency) do
    new_balance = Currency.sum(Currency.new(deposit_value, deposit_curency), account_balance)
    %FinancialSystem.Account{account | balance: new_balance}
  end

  def withdrawal(_account, withdrawal_value, _currecy)
    when withdrawal_value < 0 do
      raise("withdrawal value must be a positive number")
  end

  def withdrawal(%FinancialSystem.Account{balance: account_balance} = account, withdrawal_value, withdrawal_curency) do
    status = has_fund?(account, withdrawal_value)
    new_balance = Currency.sub(Currency.new(withdrawal_value, withdrawal_curency), account_balance)
    %FinancialSystem.Account{account | balance: new_balance}
  end

  def has_fund?(%FinancialSystem.Account{balance: %{amount: account_fund}}, value)
    when account_fund < value do
      raise("insufficient balance to complete the withdrawal")
  end

  def check_account_balance(%FinancialSystem.Account{balance: %{amount: account_fund, currency: currency}}) do
    currencies =
    Currency.get_currencies()
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    currency_name  = Map.get(currencies,currency)["symbol"]["grapheme"]
    currency_name <> Decimal.to_string(account_fund)

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
