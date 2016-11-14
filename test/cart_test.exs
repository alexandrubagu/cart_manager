defmodule CartTest do
  use ExUnit.Case
  doctest Cart

  @basket_number 50

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
    product_id = 1;

    pids 
      |> Enum.each(fn(basket_pid) ->
        Basket.add_product(basket_pid, product_id)
      end) 

    pids 
      |> Enum.each(fn(basket_pid) ->
        Basket.delete_product(basket_pid, product_id)
      end)

    pids 
      |> Enum.each(fn(basket_pid) ->
        Basket.add_product(basket_pid, product_id)
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

  test "handle info" do
    user_id = 1
    basket_id = Basket.Manager.create_basket_or_return_basket_id(Basket.Manager, user_id)
    basket_pid = Basket.Manager.get_basket(Basket.Manager, basket_id)
    basket_ref = Process.monitor(basket_pid)
    Basket.Manager.handle_info({:DOWN, basket_ref, :process, basket_pid, :normal}, {%{user_id => basket_id}, %{basket_id => basket_pid}})
  end
end
