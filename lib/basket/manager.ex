defmodule Basket.Manager do
    use GenServer

    def init([]) do
        user_basket = %{}
        basket_pid  = %{}
        {:ok, {user_basket, basket_pid}}
    end

    #################
    #### Client  ####
    #################
    def start_link do
        GenServer.start_link(__MODULE__, [], name: Basket.Manager)
    end

    def create_basket_or_return_basket_id(pid, user_id) do
        GenServer.call(pid, {:create_basket_or_return_basket_id, user_id})
    end

    def get_basket(pid, basket_id) do
        GenServer.call(pid, {:get_basket, basket_id})
    end

    ################
    #### Server ####
    ################
    def handle_call({:create_basket_or_return_basket_id, user_id}, _from, {user_basket, basket_pid} = state) do        
        if Map.has_key?(user_basket, user_id) do
            #return basket_id
            {:reply, Map.fetch!(user_basket, user_id), state}
        else
            #generate new basket_id
            keys = Map.values(user_basket)
            basket_id = if Enum.empty?(keys) do
                1
            else 
                Enum.max(keys) + 1 
            end

            #create new Basket agent
            {:ok, pid} = Supervisor.start_child(Basket.Supervisor, [])
            Process.monitor(pid)

            #update states
            user_basket = Map.put(user_basket, user_id, basket_id)
            basket_pid = Map.put(basket_pid, basket_id, pid)

            #send reply
            {:reply, basket_id, {user_basket, basket_pid}}
        end
    end 

    def handle_call({:get_basket, basket_id}, _from, {_user_basket, basket_pid} = state) do        
        if Map.has_key?(basket_pid, basket_id) do
            {:reply, Map.fetch!(basket_pid, basket_id), state}
        end
    end 

    def handle_info({:DOWN, _ref, :process, _pid, {:shutdown, _basket_state}}, {user_basket, basket_pid}) do
        IO.puts "basket purchased info ..."
        # here you can notify other baskets about the purchase
        # also you can persist bought basket to database
        {:noreply, {user_basket, basket_pid}}
    end

    def handle_info({:DOWN, _ref, :process, pid, _reason}, {user_basket, basket_pid}) do
        IO.puts "handle info ..."
        # clear and update state
        {user_basket, basket_pid} = with found_basket_pid <- Enum.find(basket_pid, fn({_, basket_pid}) -> basket_pid == pid end),
            true <- is_tuple(found_basket_pid),
            found_basket_id <- found_basket_pid |> elem(0),
            found_user_basket <- Enum.find(user_basket, fn({_, basket_id}) -> found_basket_id == basket_id end),
            true <- is_tuple(found_user_basket),
            found_user_id <- found_user_basket |> elem(0), 
            do: {Map.delete(user_basket, found_user_id), Map.delete(basket_pid, found_basket_id)}
        {:noreply, {user_basket, basket_pid}}
    end

    def handle_info(_msg, state) do
        {:noreply, state}
    end
end
