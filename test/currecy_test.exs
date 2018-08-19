defmodule CurrencyTest do
  use ExUnit.Case
  doctest Currency

  test "Error when creating a currency using a negative amount" do
    assert_raise ArgumentError, fn ->
      Currency.new!(-10.0, :BRL)
    end
  end

  test "Error when creating a currency using a code not in compliance with ISO 4217" do
    assert_raise ArgumentError, fn ->
      Currency.new!(10.0, :TEMERS)
    end
  end

  test "Creates a currency with arbitrary precision" do
    assert Currency.new!(20, :JPY) ==
             %Currency.Money{
               amount: Decimal.new("20"),
               currency: :JPY,
               precision: 0,
               atom: Decimal.new("1.0")
             }
  end

  test "Normalize currency precision" do
    assert Currency.new!(20.892932737, :JPY) ==
             %Currency.Money{
               amount: Decimal.new("20"),
               currency: :JPY,
               precision: 0,
               atom: Decimal.new("1.0")
             }
  end

  test "Error when summing up two different currencies" do
    a = Currency.new!(10, :BRL)
    b = Currency.new!(10, :USD)
    {status, _result} = Currency.sum(a, b)
    assert status == :error
  end

  test "Error when subtraction results less than zero" do
    a = Currency.new!(10, :BRL)
    b = Currency.new!(20, :BRL)
    {status, _result} = Currency.sub(a, b)
    assert status == :error
  end

  test "Error when subtracting two different currencies" do
    a = Currency.new!(10, :BRL)
    b = Currency.new!(10, :USD)

    {status, _result} = Currency.sub(a, b)
    assert status == :error
  end

  test "Error when users input a non positive number as multiplier" do
    a = Currency.new!(10, :BRL)

    {status, _result} = Currency.mult(a, -1)
    assert status == :error
  end

  test "Error when users input a non positive number as divider" do
    a = Currency.new!(10, :BRL)
    {status, _result} = Currency.div(a, -1)
    assert status == :error
  end

  test "Checks non exact divisions" do
    a = Currency.new!(10, :JPY)
    {:ok, result: %{amount: result_amount}, rem: %{amount: rem_amount}} = Currency.div(a, 3)
    assert {result_amount, rem_amount} = {Decimal.new("3"), Decimal.new("1")}
  end

  test "Checks division precision" do
    a = Currency.new!(10, :JPY)
    {:ok, result: %{amount: result_amount}, rem: %{amount: rem_amount}} = Currency.div(a, 2)
    assert {result_amount, rem_amount} = {Decimal.new("5"), Decimal.new("0")}
  end
end
