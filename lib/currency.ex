defmodule Currency do
  @moduledox """
    Provides methods for creating and handling currency in compliance with ISO 4217 rules
  """

  alias Decimal, as: D

  def new(amount, currency_code)
      when amount < 0 do
    raise("the amount must be a positive number")
  end

  def new(amount, currency_code, precision)
      when precision < 0 do
    raise(ArgumentError, message: "the precision must be bigger than 1")
  end

  @doc """
    Creates a new Money structure to be used in a financial transaction or operated
    with other money structures.

    The currency code atom must be in uppercase.

  ## Examples

      iex> Currency.new(10,:BRL)
      %Currency.Money{amount: Decimal.new("10.00"), currency: :BRL, precision: 2, symbol: nil}
  """

  def new(amount, currency_code, precision \\ 2) do
    norm_amount =
      amount
      |> D.new()
      |> D.round(precision, :floor)

    if Currency.valid_currency?(currency_code) do
      %Currency.Money{currency: currency_code, amount: norm_amount, precision: precision}
    else
      raise(ArgumentError, message: "invalid currency code")
    end
  end

  def sum(%Currency.Money{currency: currency_a}, %Currency.Money{currency: currency_b})
      when currency_a != currency_b do
    raise("different currencies")
  end

  @doc """
    Sums up two Money structures. A summation of these type of structures results in a new structure
    also of the type Money, but with the amount attribute equals to the two input structures amounts summed up.

    It will raise an error if the Money structures don't have the same currency code.

  ## Examples

      iex> a = Currency.new(10,:BRL)
      iex> b = Currency.new(10.50,:BRL)
      iex> Currency.sum(a,b)
      %Currency.Money{amount: Decimal.new("20.50"), currency: :BRL, precision: 2, symbol: nil}
  """

  def sum(
        %Currency.Money{amount: amount_a} = money_a,
        %Currency.Money{amount: amount_b} = money_b
      ) do
    %Currency.Money{money_a | amount: D.add(amount_a, amount_b)}
  end

  def sub(%Currency.Money{amount: amount_a}, %Currency.Money{amount: amount_b})
      when amount_a < amount_b do
    raise("negative result. The first argument should be greater than the second")
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
      %Currency.Money{amount: Decimal.new("10.20"), currency: :BRL, precision: 2, symbol: nil}
  """

  def sub(
        %Currency.Money{amount: amount_a} = money_a,
        %Currency.Money{amount: amount_b} = money_b
      ) do
    negative_b = %Currency.Money{money_b | amount: D.minus(amount_b)}
    Currency.sum(money_a, negative_b)
  end

  def mult(%Currency.Money{amount: amount} = money, mult_factor)
      when mult_factor < 1 do
    raise(ArgumentError, message: "the multiplier must be bigger than 1")
  end

  @doc """
    Multiplies a Money structure by a given input number. It results in a new Money structre where the
    amount attribute is equals to the input amount times the input number.

    The second argument must be a positive number.

  ## Examples

      iex> a = Currency.new(10.50,:BRL)
      iex> Currency.mult(a, 2)
      %Currency.Money{amount: Decimal.new("21.00"), currency: :BRL, precision: 2, symbol: nil}
  """

  def mult(%Currency.Money{amount: amount, precision: precision} = money, mult_factor) do
    result = D.mult(amount, D.new(mult_factor)) |> D.round(precision, :floor)
    %Currency.Money{money | amount: result}
  end

  def div(money, div_factor)
      when div_factor < 1 do
    raise(ArgumentError, message: "the divisor must be a positive number")
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
        %Currency.Money{
          amount: Decimal.new("0.00"),
          currency: :BRL,
          precision: 2,
          symbol: nil
        },
        result:
        %Currency.Money{
          amount: Decimal.new("15.00"),
          currency: :BRL,
          precision: 2,
          symbol: nil
        }
      }
  """

  def div(%Currency.Money{amount: amount, precision: precision} = money, div_factor) do
    result_amount =
      D.div(amount, D.new(div_factor))
      |> D.round(precision, :floor)

    result = %Currency.Money{money | amount: result_amount}
    rem = Currency.sub(money, Currency.mult(result, D.new(div_factor)))

    money_atom = D.new(:math.pow(10, -precision))

    if Decimal.compare(money_atom, result_amount) == D.new(1) do
      raise("value to low to be properly represented")
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

    status =
      currencies
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

  def get_currencies do
    currencies = Utils.get_json("currencies_list.json")

    case currencies do
      {:ok, currencies} -> currencies
      {:error, _reason} -> raise("currencies list not found")
    end
  end
end
