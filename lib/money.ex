defmodule Currency.Money do
  @moduledoc """
  Struct to represent money, a basic element to operate with currencies.
  """
  defstruct currency: nil, amount: nil, precision: nil, atom: nil
end
