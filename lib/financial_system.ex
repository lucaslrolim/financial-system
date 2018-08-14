defmodule FinancialSystem do
  def get_rates() do
    url = System.get_env("EXCHANGE_API")

    case HTTPoison.get(url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: body}} ->
        body
        |> Poison.decode!()
        |> Map.get(["rates"])
        |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

      {:error, %HTTPoison.Response{status_code: 404}} ->
        IO.puts("Page not found")

      {:error, %HTTPoison.Error{reason: reason}} ->
        IO.inspect(reason)
    end
  end
end
