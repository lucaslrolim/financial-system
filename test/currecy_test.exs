defmodule CurrencyTest do
  use ExUnit.Case
  doctest Currency

  test "Error when creating a currency using a negative amount" do
    assert_raise RuntimeError, fn ->
      Currency.new(-10.0, :BRL)
    end
  end

  test "Error when creating a currency using a code not in compliance with ISO 4217" do
    assert_raise ArgumentError, fn ->
      Currency.new(10.0, :TEMERS)
    end
  end

  test "Error when creating a currency using negative precision" do
    assert_raise ArgumentError, fn ->
      Currency.new(10.0, :BRL, -1)
    end
  end

  test "Creates a currency with arbitrary precision" do
    assert Currency.new(20, :JPY, 0) ==
             %Currency.Money{amount: Decimal.new("20"), currency: :JPY, precision: 0, symbol: nil}
  end

  test "Normalize currency precision" do
    assert Currency.new(20.892932737, :JPY, 0) ==
             %Currency.Money{amount: Decimal.new("20"), currency: :JPY, precision: 0, symbol: nil}
  end

  test "Error when summing up two different currencies" do
    a = Currency.new(10, :BRL)
    b = Currency.new(10, :USD)

    assert_raise RuntimeError, fn ->
      Currency.sum(a, b)
    end
  end

  test "Error when subtraction results less than zero" do
    a = Currency.new(10, :BRL)
    b = Currency.new(20, :BRL)

    assert_raise RuntimeError, fn ->
      Currency.sub(a, b)
    end
  end

  test "Error when subtracting two different currencies" do
    a = Currency.new(10, :BRL)
    b = Currency.new(10, :USD)

    assert_raise RuntimeError, fn ->
      Currency.sub(a, b)
    end
  end

  test "Error when users input a non positive number as multiplier" do
    a = Currency.new(10, :BRL)

    assert_raise ArgumentError, fn ->
      Currency.mult(a, -1)
    end
  end

  test "Error when users input a non positive number as divider" do
    a = Currency.new(10, :BRL)

    assert_raise ArgumentError, fn ->
      Currency.div(a, -1)
    end
  end

  test "Checks non exact divisions" do
    a = Currency.new(10, :JPY, 0)
    %{result: %{amount: result_amount}, rem: %{amount: rem_amount}} = Currency.div(a, 3)
    assert {result_amount, rem_amount} = {Decimal.new("3"), Decimal.new("1")}
  end

  test "Checks division precision" do
    a = Currency.new(10, :JPY, 0)
    %{result: %{amount: result_amount}, rem: %{amount: rem_amount}} = Currency.div(a, 2)
    assert {result_amount, rem_amount} = {Decimal.new("5"), Decimal.new("0")}
  end
end
