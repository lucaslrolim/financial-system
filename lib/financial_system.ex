defmodule FinancialSystem do

  def create_account(account_id, owner_name, currency) do
    %FinancialSystem.Account{
      id: account_id,
      owner: owner_name,
      currency: currency,
      balance: Currency.new(0, currency)
    }
  end

  def deposit(%FinancialSystem.Account{balance: account_balance} = account, deposit_value, deposit_curency) do
    new_balance = Currency.sum(Currency.new(deposit_value, deposit_curency), account_balance)
    %FinancialSystem.Account{account | balance: new_balance}
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
