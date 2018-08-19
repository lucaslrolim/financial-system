defmodule Currency do
  @moduledoc """
    Provides methods to creating and handling currency in compliance with ISO 4217 rules
  """

  alias Decimal, as: D

  @type money_type :: %Currency.Money{
          currency: atom,
          amount: Decimal.t(),
          precision: integer,
          atom: Decimal.t()
        }

  @spec new!(number, atom) :: money_type | no_return
  def new!(amount, _currency_code)
      when amount < 0 do
    raise(ArgumentError, message: "the amount must be a positive number")
  end

  @doc """
    Creates a new Money structure to be used in a financial transaction or operated
    with other money structures.

    The currency code must be in uppercase.

  ## Examples

      iex> Currency.new!(10,:BRL)
      %Currency.Money{amount: Decimal.new("10.00"), currency: :BRL, precision: 2, atom: Decimal.new("0.01")}
  """

  def new!(amount, currency_code) do
    if Currency.valid_currency?(currency_code) do
      precision = get_currency_precison(currency_code)

      norm_amount =
        amount
        |> D.new()
        |> D.round(precision, :floor)

      %Currency.Money{
        currency: currency_code,
        amount: norm_amount,
        precision: precision,
        atom: D.new(:math.pow(10, -precision))
      }
    else
      raise(ArgumentError, message: "invalid currency code")
    end
  end

  @spec sum(money_type, money_type) :: {:ok, money_type} | {:error, String.t()}
  def sum(%Currency.Money{currency: currency_a}, %Currency.Money{currency: currency_b})
      when currency_a != currency_b do
    {:error, "different currencies"}
  end

  @doc """
    Sums up two Money structures. The summation of these type of structures results in a new structure
    also of the type Money, but with the amount attribute equals to the two input structures amounts summed up.

  ## Examples

      iex> a = Currency.new!(10,:BRL)
      iex> b = Currency.new!(10.50,:BRL)
      iex> Currency.sum(a,b)
      {:ok, %Currency.Money{amount: Decimal.new("20.50"), currency: :BRL, precision: 2, atom: Decimal.new("0.01")}}
  """

  def sum(
        %Currency.Money{amount: amount_a} = money_a,
        %Currency.Money{amount: amount_b}
      ) do
    {:ok, %Currency.Money{money_a | amount: D.add(amount_a, amount_b)}}
  end

  @spec sub(money_type, money_type) :: {:ok, money_type} | {:error, String.t()}
  def sub(%Currency.Money{amount: amount_a}, %Currency.Money{amount: amount_b})
      when amount_a < amount_b do
    {:error, "negative result. The first argument should be greater than the second"}
  end

  @doc """
    Subtracts two Money structures. A subtraction of these type of structures results in a new structure
    also of the type Money, but with the amount attribute equals to the first input minus the second.
  ## Examples

      iex> a = Currency.new!(20.70,:BRL)
      iex> b = Currency.new!(10.50,:BRL)
      iex> Currency.sub(a,b)
      {:ok, %Currency.Money{amount: Decimal.new("10.20"), currency: :BRL, precision: 2, atom: Decimal.new("0.01")}}
  """

  def sub(
        money_a,
        %Currency.Money{amount: amount_b} = money_b
      ) do
    negative_b = %Currency.Money{money_b | amount: D.minus(amount_b)}
    Currency.sum(money_a, negative_b)
  end

  @spec mult(money_type, Decimal.t() | number) :: {:ok, money_type} | {:error, String.t()}
  def mult(_money, mult_factor)
      when mult_factor < 0 do
    {:error, "the multiplier must be a positive number"}
  end

  @doc """
    Multiplies a Money structure by a given input number. It results in a new Money structure where the
    amount attribute is equals to the input amount times the input number.
  ## Examples

      iex> a = Currency.new!(10.50,:BRL)
      iex> Currency.mult(a, 2)
      {:ok, %Currency.Money{amount: Decimal.new("21.00"), currency: :BRL, precision: 2, atom: Decimal.new("0.01")}}
  """

  def mult(
        %Currency.Money{amount: amount, precision: precision, atom: money_atom} = money,
        mult_factor
      ) do
    result = D.mult(amount, D.new(mult_factor)) |> D.round(precision, :floor)

    if D.cmp(result, money_atom) == :lt do
      {:error, "value to low to be properly represented"}
    else
      {:ok, %Currency.Money{money | amount: result}}
    end
  end

  @spec div(Currency.Money.t(), Decimal.t() | number) :: {:ok, money_type} | {:error, String.t()}
  def div(_money, div_factor)
      when div_factor < 1 do
    {:error, "the divisor must be a positive number"}
  end

  @doc """
    Divides a Money structure by a given input number. It results in a Map with two new Money structures.
    The first one *(result)* contains the amount attribut that is equals to the input amount divided by the input number.
    The second one *(rem)* contains the residue of the division, in case the value can't be equally divided.
  ## Examples

      iex> a = Currency.new!(30,:BRL)
      iex> Currency.div(a, 2)
      {:ok,
        [
        result:
        %Currency.Money{
          amount: Decimal.new("15.00"),
          currency: :BRL,
          precision: 2,
          atom: Decimal.new("0.01")
        },
        rem:
        %Currency.Money{
          amount: Decimal.new("0.00"),
          currency: :BRL,
          precision: 2,
          atom: Decimal.new("0.01"),
        }
      ]}
  """

  def div(
        %Currency.Money{amount: amount, precision: precision, atom: money_atom} = money,
        div_factor
      ) do
    result_amount =
      D.div(amount, D.new(div_factor))
      |> D.round(precision, :floor)

    result = %Currency.Money{money | amount: result_amount}
    {:ok, int_part} = Currency.mult(result, D.new(div_factor))
    {:ok, rem} = Currency.sub(money, int_part)

    %{amount: integer_amount} = result

    if D.cmp(integer_amount, money_atom) == :lt do
      {:error, "value to low to be properly represented"}
    else
      {:ok, result: result, rem: rem}
    end
  end

  @doc """
    Checks if the currency code is in compliance with ISO 4217.

  ## Examples

      iex> Currency.valid_currency?(:BRL)
      true
  """
  @spec valid_currency?(atom) :: boolean
  def valid_currency?(currecy_code) do
    Currency.get_currencies()
    |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)
    |> Map.has_key?(currecy_code)
  end

  @doc """
    Gets a list of all currencies in compliance with ISO 4217.

  ## Examples

      iex> currencies = Currency.get_currencies()
      iex> Map.get(currencies,"BRL")["name"]
      "Brazilian Real"
  """
  @spec get_currencies :: map() | String.t()
  def get_currencies do
    currencies = Utils.get_json("currencies_list.json")

    case currencies do
      {:ok, currencies} -> currencies
      {:error, _reason} -> raise("currencies list not found")
    end
  end

  @doc """
    Gets currecy precision according to ISO 4217.

  ## Examples

      iex> Currency.get_currency_precison(:BRL)
      2
  """
  @spec get_currency_precison(atom) :: number
  def get_currency_precison(currency_code) do
    currencies =
      Currency.get_currencies()
      |> Map.new(fn {k, v} -> {String.to_atom(k), v} end)

    Map.get(currencies, currency_code)["fractionSize"]
  end
end
