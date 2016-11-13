defmodule Basket.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: Basket.Supervisor])
  end

  def init(:ok) do
    children = [
      worker(Basket, [], restart: :temporary)
    ]
    supervise(children, strategy: :simple_one_for_one)
  end
end

