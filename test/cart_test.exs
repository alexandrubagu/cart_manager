defmodule CartTest do
  use ExUnit.Case
  doctest Cart

  @basket_number 100

  setup_all do
    case Cart.start([],[]) do
      {:ok, _} -> :ok
      {:error, {:already_started, _pid}} -> :ok
      _ -> raise "Error"
    end
  end

  setup do
    new_context = [ids: [], pids: []]
    new_context = Keyword.update!(new_context, :ids, fn(list) ->
      list ++ 
        1..@basket_number 
          |> Enum.map(fn(x) ->
            Basket.Manager.create_basket_or_return_basket_id(
              Basket.Manager, x
            )  
          end)
    end)
    Keyword.update!(new_context, :pids, fn(list) ->
        list ++
          new_context[:ids] 
            |> Enum.map(fn(basket_id) ->
                 Basket.Manager.get_basket(Basket.Manager, basket_id)
            end)
    end)
  end

  test "basket manager is started" do
    assert is_pid(Process.whereis(Basket.Manager))
  end

  test "basket supervisor is started" do
    assert is_pid(Process.whereis(Basket.Supervisor))
  end

  test "basket pids were created", %{pids: pids} do
    stream = pids 
      |> Stream.filter(fn(x) ->
        !is_pid(x)
      end)
    assert length(Enum.to_list(stream)) == 0
  end

  test "basket ids were created", %{ids: ids} do
    stream = ids 
      |> Stream.filter(fn(x) ->
        !is_number(x)
      end)
    assert length(Enum.to_list(stream)) == 0
  end

  test "create one basket and the purhase" do
    {:ok, pid} = Basket.start_link
    Basket.add_product(pid, :os.timestamp)
    Agent.stop(pid)
  end

  test "add product to baskets and the purchase", %{pids: pids} do 
    pids 
      |> Enum.each(fn(basket_pid) ->
        Basket.add_product(basket_pid, :os.timestamp)
      end) 
  
    pids 
      |> Enum.filter(fn(basket_pid) ->
          %{notification: nil, products: []} == Basket.get_basket(basket_pid) 
      end) 
  
    pids 
      |> Enum.each(fn(basket_pid) ->
        Basket.purchase(basket_pid)
      end)
  end
end
