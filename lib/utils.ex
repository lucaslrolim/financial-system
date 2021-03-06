defmodule Utils do
  @moduledoc """
  Utility functions.
  """
  def get_json(filename) do
    with {:ok, body} <- File.read(filename), {:ok, json} <- Poison.decode(body), do: {:ok, json}
  end
end
