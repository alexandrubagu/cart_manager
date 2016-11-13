#####################
#### FOR TESTING ####
#####################
defmodule Basket do
    def start_link do
        Agent.start_link(fn -> %{products: [], notification: nil} end, [])
    end

    def add_product(pid, new_product_id) do
        Agent.update(pid, fn basket -> 
            %{basket | products: basket.products ++ [new_product_id]}     
        end)
    end

    def delete_product(pid, new_product_id) do
        Agent.update(pid, fn basket -> 
            stream = Stream.filter(basket.products, fn(product_id) ->
                product_id != new_product_id
            end)
            %{basket | products: Enum.to_list(stream)}
        end)
    end

    def get_basket(pid) do
        Agent.get(pid, fn(state) ->
            state
        end)
    end

    def purchase(pid) do
        Agent.stop(pid, {:shutdown, get_basket(pid)})
    end
end