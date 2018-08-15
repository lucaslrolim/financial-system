defmodule Currency do
  @moduledox """
    Provides methods for creating and handling currency in compliance with ISO 4217 rules
  """

  alias Decimal, as: D

  def new(amount, currency_code)
      when amount < 0 do
    raise("ERROR: The amount must be a positive number")
  end

  @doc """
    Creates a new Money structure to be used in a financial transaction or operated
    with other money structures.

    The currency code atom must be in uppercase.

  ## Examples

      iex> Currency.new(10,:BRL)
      %Finance.Money{ amount: Decimal.new("10.00"), currency: :BRL, precision: 2, symbol: nil }
  """

  def new(amount, currency_code, precision \\ 2) do
    norm_amount =
      amount
      |> D.new()
      |> D.round(precision, :floor)


    if Currency.valid_currency?(currency_code) do
      %Finance.Money{currency: currency_code, amount: norm_amount, precision: precision}
    else
      raise(ArgumentError, message: "ERROR: invalid currency code")
    end

  end

  def sum(%Finance.Money{currency: currency_a}, %Finance.Money{currency: currency_b})
      when currency_a != currency_b do
    raise("ERROR: Different currencies.")
  end

  @doc """
    Sums up two Money structures. A summation of these type of structures results in a new structure
    also of the type Money, but with the amount attribute equals to the two input structures amounts summed up.

    It will raise an error if the Money structures don't have the same currency code.

  ## Examples

      iex> a = Currency.new(10,:BRL)
      iex> b = Currency.new(10.50,:BRL)
      iex> Currency.sum(a,b)
      %Finance.Money{ amount: Decimal.new("20.50"), currency: :BRL, precision: 2, symbol: nil }
  """

  def sum(a, b) do
    %Finance.Money{a | amount: D.add(a.amount, b.amount)}
  end

  def sub(%Finance.Money{amount: amount_a}, %Finance.Money{amount: amount_b})
      when amount_a < amount_b do
    raise("ERROR: Negative result. The first argument should be greater than the second.")
  end

  @doc """
    Subtract two Money structures. A subtraction of these type of structures results in a new structure
    also of the type Money, but with the amount attribute equals to the first input minus the second.

    The Money structes must have the same currency code or it will raise an error.

    As it's impossible to have negative amounts of money, the first argument must have an amount value
    greater than the second.

  ## Examples

      iex> a = Currency.new(20.70,:BRL)
      iex> b = Currency.new(10.50,:BRL)
      iex> Currency.sub(a,b)
      %Finance.Money{ amount: Decimal.new("10.20"), currency: :BRL, precision: 2, symbol: nil }
  """

  def sub(a, b) do
    negative_b = %Finance.Money{b | amount: D.minus(b.amount)}
    Currency.sum(a, negative_b)
  end

  def mult(a, mult_factor)
      when mult_factor < 1 do
    raise("ERROR: Invalid multiplier.")
  end

  @doc """
    Multiplies a Money structure by a given input number. It results in a new Money structre where the
    amount attribute is equals to the input amount times the input number.

    The second argument must be a positive number.

  ## Examples

      iex> a = Currency.new(10.50,:BRL)
      iex> Currency.mult(a, 2)
      %Finance.Money{ amount: Decimal.new("21.00"), currency: :BRL, precision: 2, symbol: nil }
  """

  def mult(a, mult_factor) do
    %Finance.Money{a | amount: D.mult(a.amount, mult_factor)}
  end

  def div(a, div_factor)
      when div_factor <= 0 do
    raise("ERROR: Invalid divisor.")
  end

  @doc """
    Divides a Money structure by a given input number. It results in a Map with two new Money structres.
    The first one (result) contains the amount attribut that is equals to the input amount divided by the input number.
    The second one (rem) contains the residue of the division, in case the value can't be equally divided

    The second argument must be a positive number.

    The method will raise an error if the result was minor than the atomic element of the currecy.
      e.g: A currency that have 2 digits precision will raise an error if the result is less than 0.01

  ## Examples

      iex> a = Currency.new(30,:BRL)
      iex> Currency.div(a, 2)
      %{
        rem:
        %Finance.Money{
          amount: Decimal.new("0.00"),
          currency: :BRL,
          precision: 2,
          symbol: nil
        },
        result:
        %Finance.Money{
          amount: Decimal.new("15.00"),
          currency: :BRL,
          precision: 2,
          symbol: nil
        }
      }
  """

  def div(a, div_factor) do
    result_amount =
      D.div(a.amount, div_factor)
      |> D.round(a.precision, :floor)

    result = %Finance.Money{a | amount: result_amount}
    rem = Currency.sub(a, Currency.mult(result, div_factor))

    money_atom = D.new(:math.pow(10, -a.precision))

    if result_amount < money_atom do
      raise("ERROR: Value to low to be properly represented.")
    end

    %{result: result, rem: rem}
  end

  @doc """
    Checks if the currency code is in compliance with ISO 4217.

  ## Examples

      iex> Currency.valid_currency?(:BRL)
      true
  """

  def valid_currency?(currecy_code) do
      currencies = Currency.get_currencies()

      status = currencies
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
      |> Map.has_key?(currecy_code)

  end

  @doc """
    Gets a list of all currencies in compliance with ISO 4217.

  ## Examples

      iex> currencies = Currency.get_currencies()
      iex> Map.get(currencies,"BRL")
      "Brazilian Real"
  """

  def get_currencies() do
    currencies = Utils.get_json("currencies_list.json")

    case currencies do
      {:ok, currencies} -> currencies
      {:error, _reason} -> raise("ERROR: Currencies list not found.")
    end
  end

end
