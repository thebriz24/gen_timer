defmodule GenTimer do
  use GenServer

  def start(function, args, duration), do: start_repeated(function, args, duration, 1)
  def start_repeated(function, args, duration, times \\ :infinite) do
    GenServer.start(__MODULE__, %{function: function, args: args, duration: duration, times: times}, name: GenTimer)
  end

  def start_link(function, args, duration), do: start_link_repeated(function, args, duration, 1)
  def start_link_repeated(function, args, duration, times \\ :infinite) do
    GenServer.start_link(__MODULE__, %{function: function, args: args, duration: duration, times: times}, name: GenTimer)
  end

  def init(%{duration: duration, times: :infinite} = state) do
    schedule_work(:perform_and_reschedule, duration)
    {:ok, state}
  end
  def init(%{duration: duration} = state) do
    state = Map.update(state, :times, 0, fn(times) ->
      schedule_remaining(duration, times)
    end)
    {:ok, state}
  end

  def last_returned_value(timer) do
    GenServer.call(timer, :last_returned_value)
  end

  defp schedule_work(:perform, duration) do
    Process.send_after(self(), :perform, duration)
  end
  defp schedule_work(:perform_and_reschedule, duration) do
    Process.send_after(self(), :perform_and_reschedule, duration)
  end

  defp schedule_remaining(duration, :infinite) do
    schedule_work(:perform_and_reschedule, duration)
    :infinite
  end
  defp schedule_remaining(duration, times) do
    if times > 1 do
      schedule_work(:perform_and_reschedule, duration)
    else
      schedule_work(:perform, duration)
    end
    times - 1
  end

  ## Callbacks

  def handle_info(:perform, state) do
    return = apply(state.function, state.args)
    state = Map.put(state, :return, return)
    {:stop, :normal, state}
  end
  def handle_info(:perform_and_reschedule, state) do
    return = apply(state.function, state.args)
    state = state
    |> Map.update(:times, 0, fn(times) -> schedule_remaining(state.duration, times) end)
    |> Map.put(:return, return)
    {:noreply, state}
  end

  def handle_call(:last_returned_value, _from, state) do
    return = Map.get(state, :return)
    {:reply, return, state}
  end
end
