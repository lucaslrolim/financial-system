defmodule Finance do

  alias Decimal, as: D

  def new(amount,currency)
    when amount < 0 do
      raise("ERROR: The amount must be a positive number")
  end

  def new(amount, currency) do
    precision = 2 # temp variable for to be used in tests

    norm_amount = amount
                  |> D.new
                  |> D.round(precision, :floor)

    %Finance.Money{currency: currency, amount: norm_amount, precision: precision}
  end

  def add(%Finance.Money{currency: currency_a}, %Finance.Money{currency: currency_b})
    when currency_a != currency_b do
      raise("ERROR: Different currencies.")
  end

  def add(a,b) do
    %Finance.Money{a | amount: D.add(a.amount, b.amount) }
  end

  def sub(%Finance.Money{amount: amount_a}, %Finance.Money{amount: amount_b})
    when amount_a < amount_b do
      raise("ERROR: Negative result. The first argument should be greater than the second.")
  end

  def sub(a, b) do
    %Finance.Money{a | amount: D.add(a.amount, D.minus(b.amount) ) }
  end

  def multiply(a, mult_factor) do
    %Finance.Money{a | amount: D.mult(a.amount, mult_factor) }
  end

end
