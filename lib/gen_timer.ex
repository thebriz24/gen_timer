defmodule GenTimer do
  @moduledoc ~S"""
  A GenServer for asynchronously running a function after some duration.

  ## Usage
  Register a function and a duration. The function will be called after the duration. If using `start_repeated/4` or
  `start_link_repeated/4` it will continue for the specified amount of times.
  """
  use GenServer

  @doc """
    Starts a `GenServer` process without links (outside of a supervision tree). The `function` is registered. After the
    `duration` the function will be called using specified `args`.
  """
  @spec start((... -> any()), list(), non_neg_integer()) :: GenServer.on_start()
  def start(function, args, duration), do: start_repeated(function, args, duration, 1)

  @doc """
    The same as `start/3` but allows to specify an amount of `times` to repeat, defaulting to `:infinite`.
  """
  @spec start_repeated((... -> any()), list(), non_neg_integer(), non_neg_integer() | :infinite) ::
          GenServer.on_start()
  def start_repeated(function, args, duration, times \\ :infinite) do
    GenServer.start(
      __MODULE__,
      %{function: function, args: args, duration: duration, times: times},
      name: GenTimer
    )
  end

  @doc """
    Starts a `GenServer` process linked to the current process. The `function` is registered. After the
    `duration` the function will be called using specified `args`.
  """
  @spec start_link((... -> any()), list(), non_neg_integer()) :: GenServer.on_start()
  def start_link(function, args, duration), do: start_link_repeated(function, args, duration, 1)

  @doc """
    The same as `start_link/3` but allows to specify an amount of `times` to repeat, defaulting to `:infinite`.
  """
  @spec start_link_repeated(
          (... -> any()),
          list(),
          non_neg_integer(),
          non_neg_integer() | :infinite
        ) :: GenServer.on_start()
  def start_link_repeated(function, args, duration, times \\ :infinite) do
    GenServer.start_link(
      __MODULE__,
      %{function: function, args: args, duration: duration, times: times},
      name: GenTimer
    )
  end

  @doc """
    Synchronously calls the `GenServer` at `pid` to receive the last value returned by the registered function. All previous
    returned values will not be kept.
  """
  @spec last_returned_value(pid()) :: any()
  def last_returned_value(pid) do
    GenServer.call(pid, :last_returned_value)
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

  def init(%{duration: duration, times: :infinite} = state) do
    schedule_work(:perform_and_reschedule, duration)
    {:ok, state}
  end

  def init(%{duration: duration} = state) do
    state =
      Map.update(state, :times, 0, fn times ->
        schedule_remaining(duration, times)
      end)

    {:ok, state}
  end

  def handle_info(:perform, state) do
    return = apply(state.function, state.args)
    state = Map.put(state, :return, return)
    {:stop, :normal, state}
  end

  def handle_info(:perform_and_reschedule, state) do
    return = apply(state.function, state.args)

    state =
      state
      |> Map.update(:times, 0, fn times -> schedule_remaining(state.duration, times) end)
      |> Map.put(:return, return)

    {:noreply, state}
  end

  def handle_call(:last_returned_value, _from, state) do
    return = Map.get(state, :return)
    {:reply, return, state}
  end
end
