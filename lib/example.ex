defmodule GenTimer.Example do
  @moduledoc false
  use GenTimer
  require Logger

  def start_link(args) do
    GenTimer.start_link(__MODULE__, args, name: __MODULE__)
  end

  def stop do
    GenServer.cast(__MODULE__, :stop)
  end

  @impl true
  def init(%{message: message}) do
    {:ok, %{milli: 1000, times: :infinite, message: message}}
  end

  @impl true
  def repeated_function(%{message: message} = state) do
    Map.put(state, :last_return, Logger.debug(message))
  end

  @impl true
  def handle_cast(:stop, state) do
    Logger.debug("Stopping")
    {:stop, :normal, state}
  end
end
