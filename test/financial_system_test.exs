defmodule FinancialSystemTest do
  use ExUnit.Case
  doctest FinancialSystem

  setup_all do
    {
      :ok,
      [
        account_1: FinancialSystem.create_account!(1, "Lucas Rolim", :BRL),
        account_2: FinancialSystem.create_account!(2, "Dolores Abernathy", :BRL),
        account_3: FinancialSystem.create_account!(3, "Robert Ford", :BRL),
        account_4: FinancialSystem.create_account!(4, "Maeve Millay", :BRL),
        account_5: FinancialSystem.create_account!(5, "Elon Musk", :USD),
        account_6: FinancialSystem.create_account!(6, "Satoshi Nakamoto", :JPY),
        account_7: FinancialSystem.create_account!(7, "Light Yagami", :JPY)
      ]
    }
  end

  test "Error when user deposits a negative value", %{account_1: account} do
    assert_raise ArgumentError, fn ->
      FinancialSystem.deposit!(account, -10.0, :BRL)
    end
  end

  test "Error when depositing a currency not supported on the account", %{account_1: account} do
    assert_raise ArgumentError, fn ->
      FinancialSystem.deposit!(account, 10.0, :USD)
    end
  end

  test "Error when operating an amount to low to the currency", %{account_1: account} do
    assert_raise ArgumentError, fn ->
      FinancialSystem.deposit!(account, 0.00001, :BRL)
    end
  end

  test "Error when withdrawal a negative amount", %{account_1: account} do
    assert_raise ArgumentError, fn ->
      FinancialSystem.withdrawal!(account, -5, :BRL)
    end
  end

  test "Error when tries a withdrawal and have no funds", %{account_1: account} do
    assert_raise RuntimeError, fn ->
      FinancialSystem.withdrawal!(account, 100, :BRL)
    end
  end

  test "Error when tries a transfer! and have no funds", %{account_1: sender, account_2: receiver} do
    assert_raise RuntimeError, fn ->
      FinancialSystem.transfer!(sender, receiver, 100)
    end
  end

  test "Error when tries to do a normal transfer! between accounts that use the same currency", %{
    account_1: sender,
    account_6: receiver
  } do
    assert_raise RuntimeError, fn ->
      FinancialSystem.transfer!(sender, receiver, 100)
    end
  end

  test "Error when tries international transfer! and have no funds after exchange", %{
    account_6: sender,
    account_1: receiver
  } do
    sender = FinancialSystem.deposit!(sender, 100, :JPY)

    assert_raise RuntimeError, fn ->
      FinancialSystem.transfer_international!(sender, receiver, :BRL, 100)
    end
  end

  test "Error when split transfer! percent inputs don't sum 1", %{
    account_1: sender,
    account_2: receiver_1,
    account_3: receiver_2
  } do
    sender = FinancialSystem.deposit!(sender, 100, :BRL)

    assert_raise ArgumentError, fn ->
      FinancialSystem.split_transfer!(sender, [receiver_1, receiver_2], 50, [0.5, 0.4])
    end
  end

  test "Error when all receivers don't use the same currency", %{
    account_1: sender,
    account_2: receiver_1,
    account_6: receiver_2
  } do
    sender = FinancialSystem.deposit!(sender, 100, :BRL)

    assert_raise ArgumentError, fn ->
      FinancialSystem.split_transfer!(sender, [receiver_1, receiver_2], 50, [0.5, 0.4])
    end
  end
end
